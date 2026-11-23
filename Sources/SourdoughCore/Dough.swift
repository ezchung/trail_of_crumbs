/*
This is the dough: the data behind every jar on the shelf.
The jar is only the look; it reads a Dough and draws it.

Starter vs dough:
- A starter lives on forever: you feed it and take some out.
- A dough (bread, pizza) is mixed once and used up. It can't be fed.
Both are the same `Dough` type, so the shelf is one list and every jar works the same.

A Dough only stores its history (`events`). Grams, last fed and the face
are all worked out from that list. See JarEvent.swift for why.
*/

import Foundation

public enum DoughType: String, Codable, Sendable {
    case starter, bread, pizza

    /// True for a starter, false for bread or pizza dough.
    public var isStarter: Bool { self == .starter }
}

public enum DoughError: Error, Equatable {
    /// Only starters can be fed. Bread and pizza dough are mixed once.
    case onlyStartersCanBeFed
    /// You can't keep more starter than is in the jar.
    case cannotKeepMoreThanInJar
}

public struct Dough: Codable, Sendable, Identifiable {
    public var id: UUID
    public var name: String
    public var type: DoughType
    public var schedule: FeedingSchedule
    public var createdAt: Date
    /// Everything that happened to this jar, oldest first.
    public private(set) var events: [JarEvent]

    /// A brand-new jar. Records a `started` event at `startedAt`.
    /// For a starter you already had, use the time you last fed it.
    public init(
        id: UUID = UUID(),
        name: String,
        type: DoughType,
        grams: Double,
        schedule: FeedingSchedule = .every12Hours,
        isNewStarter: Bool = false,
        startedAt: Date
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.schedule = schedule
        self.createdAt = startedAt
        self.events = [JarEvent(at: startedAt, kind: .started(grams: grams, isNewStarter: isNewStarter))]
    }

    /// Rebuild a jar from saved data (e.g. rows loaded from the database).
    public init(id: UUID, name: String, type: DoughType, schedule: FeedingSchedule, createdAt: Date, events: [JarEvent]) {
        self.id = id
        self.name = name
        self.type = type
        self.schedule = schedule
        self.createdAt = createdAt
        self.events = events.sorted { $0.at < $1.at }
    }

    // MARK: - Worked out from events

    /// Grams in the jar right now, from replaying every event.
    public var grams: Double {
        events.reduce(0) { grams, event in
            switch event.kind {
            case .started(let g, _): g
            case .fed(let kept, let flour, let water): min(kept, grams) + flour + water
            case .tookOut(let g, _): max(0, grams - g)
            case .addedWater(let g): grams + g
            case .movedToFridge, .movedToCounter, .reported: grams
            }
        }
    }

    /// When it was last fed (or started, if never fed).
    public var lastFed: Date {
        currentLife.last { if case .fed = $0.kind { true } else { false } }?.at ?? currentLife[0].at
    }

    public var isInFridge: Bool {
        for event in currentLife.reversed() {
            if event.kind == .movedToFridge { return true }
            if event.kind == .movedToCounter { return false }
        }
        return false
    }

    /// Events since the last `started` (a restart wipes the slate clean).
    var currentLife: ArraySlice<JarEvent> {
        let start = events.lastIndex { if case .started = $0.kind { true } else { false } } ?? 0
        return events[start...]
    }

    // MARK: - Actions (each one just records an event)

    /// Keep `keeping` grams (default: everything), then add flour + water.
    public mutating func feed(flour: Double, water: Double, keeping: Double? = nil, at now: Date) throws {
        guard type.isStarter else { throw DoughError.onlyStartersCanBeFed }
        let kept = keeping ?? grams
        guard kept <= grams else { throw DoughError.cannotKeepMoreThanInJar }
        record(.fed(kept: kept, flour: flour, water: water), at: now)
    }

    /// Take some out (for a bake, discard...). Works for every type. Never goes below 0.
    public mutating func takeOut(_ amount: Double, reason: TakeOutReason = .discard, at now: Date) {
        record(.tookOut(grams: amount, reason: reason), at: now)
    }

    public mutating func addWater(_ amount: Double, at now: Date) {
        record(.addedWater(grams: amount), at: now)
    }

    public mutating func moveToFridge(at now: Date) { record(.movedToFridge, at: now) }
    public mutating func moveToCounter(at now: Date) { record(.movedToCounter, at: now) }

    public mutating func report(_ report: Report, at now: Date) {
        record(.reported(report), at: now)
    }

    /// Start over (e.g. after Spoiled). Earlier history stays for the Journal.
    public mutating func restart(grams: Double, asNewStarter: Bool, at now: Date) {
        record(.started(grams: grams, isNewStarter: asNewStarter), at: now)
    }

    /// Undo: remove the most recent event (never the very first `started`).
    public mutating func undoLast() {
        if events.count > 1 { events.removeLast() }
    }

    private mutating func record(_ kind: JarEvent.Kind, at date: Date) {
        events.append(JarEvent(at: date, kind: kind))
    }
}
