/*
The database shapes (one struct per table) and how they convert to and from
SourdoughCore types. Same idea as RecipeDTO: Core never knows about Supabase,
and the database layout can change without touching the face rules.
*/

import Foundation
import SourdoughCore

/// One row of `public.jars`. `user_id` is left out: the database fills it in.
struct JarRow: Codable, Equatable {
    var id: UUID
    var name: String
    var type: String
    var scheduleHours: Int
    var createdAt: Date
    /// Filled when loaded with `select("*, jar_events(*)")`. Not sent on insert.
    var jarEvents: [EventRow]?

    enum CodingKeys: String, CodingKey {
        case id, name, type
        case scheduleHours = "schedule_hours"
        case createdAt = "created_at"
        case jarEvents = "jar_events"
    }
}

/// One row of `public.jar_events`. Unused columns stay nil.
struct EventRow: Codable, Equatable {
    var id: UUID
    var jarId: UUID
    var at: Date
    var kind: String
    var grams: Double? = nil
    var isNewStarter: Bool? = nil
    var kept: Double? = nil
    var flour: Double? = nil
    var water: Double? = nil
    var reason: String? = nil
    var report: String? = nil
    var heavy: Bool? = nil

    enum CodingKeys: String, CodingKey {
        case id, at, kind, grams, kept, flour, water, reason, report, heavy
        case jarId = "jar_id"
        case isNewStarter = "is_new_starter"
    }
}

/// A row the app can't understand (e.g. a typo'd kind added by hand in the dashboard).
public struct UnreadableRow: Error, Equatable {
    public var id: UUID
    public var why: String
}

// MARK: - Core → row

extension JarRow {
    init(_ dough: Dough) {
        self.init(id: dough.id, name: dough.name, type: dough.type.rawValue,
                  scheduleHours: dough.schedule.rawValue, createdAt: dough.createdAt, jarEvents: nil)
    }
}

extension EventRow {
    init(_ event: JarEvent, jarId: UUID) {
        self.init(id: event.id, jarId: jarId, at: event.at, kind: "")
        switch event.kind {
        case .started(let g, let isNew):
            kind = "started"; grams = g; isNewStarter = isNew
        case .fed(let k, let f, let w):
            kind = "fed"; kept = k; flour = f; water = w
        case .tookOut(let g, let r):
            kind = "took_out"; grams = g; reason = r.rawValue
        case .addedWater(let g):
            kind = "added_water"; grams = g
        case .movedToFridge:
            kind = "moved_to_fridge"
        case .movedToCounter:
            kind = "moved_to_counter"
        case .reported(let r):
            kind = "reported"
            switch r {
            case .liquidOnTop(let h): report = "liquid_on_top"; heavy = h
            case .dryOrThick: report = "dry_or_thick"
            case .pinkStreaks: report = "pink_streaks"
            case .peaked: report = "peaked"
            case .doubled: report = "doubled"
            }
        }
    }
}

// MARK: - Row → Core

extension EventRow {
    func toEvent() throws -> JarEvent {
        func need<T>(_ value: T?, _ column: String) throws -> T {
            guard let value else { throw UnreadableRow(id: id, why: "\(kind) is missing \(column)") }
            return value
        }

        let k: JarEvent.Kind
        switch kind {
        case "started":
            k = .started(grams: try need(grams, "grams"), isNewStarter: isNewStarter ?? false)
        case "fed":
            k = .fed(kept: try need(kept, "kept"), flour: try need(flour, "flour"), water: try need(water, "water"))
        case "took_out":
            k = .tookOut(grams: try need(grams, "grams"),
                         reason: TakeOutReason(rawValue: reason ?? "") ?? .discard)
        case "added_water":
            k = .addedWater(grams: try need(grams, "grams"))
        case "moved_to_fridge":
            k = .movedToFridge
        case "moved_to_counter":
            k = .movedToCounter
        case "reported":
            switch report {
            case "liquid_on_top": k = .reported(.liquidOnTop(heavy: heavy ?? false))
            case "dry_or_thick": k = .reported(.dryOrThick)
            case "pink_streaks": k = .reported(.pinkStreaks)
            case "peaked": k = .reported(.peaked)
            case "doubled": k = .reported(.doubled)
            default: throw UnreadableRow(id: id, why: "unknown report \(report ?? "nil")")
            }
        default:
            throw UnreadableRow(id: id, why: "unknown kind \(kind)")
        }
        return JarEvent(id: id, at: at, kind: k)
    }
}

extension JarRow {
    func toDough() throws -> Dough {
        guard let type = DoughType(rawValue: type) else { throw UnreadableRow(id: id, why: "unknown type \(type)") }
        guard let schedule = FeedingSchedule(rawValue: scheduleHours) else {
            throw UnreadableRow(id: id, why: "unknown schedule \(scheduleHours)")
        }
        let events = try (jarEvents ?? []).map { try $0.toEvent() }
        guard events.contains(where: { if case .started = $0.kind { true } else { false } }) else {
            throw UnreadableRow(id: id, why: "jar has no started event")
        }
        return Dough(id: id, name: name, type: type, schedule: schedule, createdAt: createdAt, events: events)
    }
}
