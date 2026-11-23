/*
Picks a starter jar's face. This is STARTER_RULES.md turned into code:
the checks below run in the same order as the "Faces" table there,
and the first one that matches wins.
*/

import Foundation

public enum Face: String, Codable, Sendable, CaseIterable {
    case spoiled, starving, sleepy, hungry, baby, thirsty, rising, ready
}

/// Everything the UI needs to draw a starter jar and its detail popup.
public struct StarterStatus: Equatable, Sendable {
    public var face: Face

    /// When it peaks / when it falls, for "peaks in ~1 h" text. Nil in the fridge.
    public var readyAt: Date?
    public var hungryAt: Date?
    /// True when the peak times are a guess (ratio KA didn't test). Show "estimate".
    public var isEstimate: Bool

    /// When the next feeding is due (for notifications).
    public var nextFeedDue: Date

    /// "Feed every 12 h until it doubles within 6–8 h." (KA-feed, KA-forgot)
    public var isReviving: Bool
    /// Lots of / dark hooch: "two or more days of twice-a-day feedings" (KA-hooch).
    public var isLongRevival: Bool
    /// Last feeding was under 1:1:1, KA's minimum (KA-ratios).
    public var fedBelowMinimum: Bool
    /// Day 1, 2, 3… of a Baby starter (KA-create day plan). Nil once grown up.
    public var babyDay: Int?
}

extension Dough {
    /// The starter's face and timings at `now`. Nil for bread / pizza dough,
    /// whose rules aren't researched yet (STARTER_RULES.md → Not covered yet).
    public func starterStatus(at now: Date) -> StarterStatus? {
        guard type.isStarter else { return nil }
        let life = Array(currentLife)

        // The `started` event that begins this life.
        guard case .started(_, let isNewStarter) = life[0].kind else { return nil }
        let startedAt = life[0].at

        // Last feeding, and everything that happened after it.
        let feedIndex = life.lastIndex { if case .fed = $0.kind { true } else { false } }
        let fedAt = feedIndex.map { life[$0].at } ?? startedAt
        let sinceFeed = feedIndex.map { Array(life[($0 + 1)...]) } ?? Array(life.dropFirst())
        let reportsSinceFeed = sinceFeed.compactMap { event -> (Date, Report)? in
            if case .reported(let r) = event.kind { (event.at, r) } else { nil }
        }

        // --- Facts from the history ---

        let spoiled = life.contains { $0.kind == .reported(.pinkStreaks) }

        let hooch = reportsSinceFeed.last { if case .liquidOnTop = $0.1 { true } else { false } }
        let starving = hooch != nil

        let doubledTimes = life.filter { $0.kind == .reported(.doubled) }.map(\.at)
        let isBaby = isNewStarter && doubledTimes.isEmpty
        let babyDay = isBaby ? Int(now.timeIntervalSince(startedAt) / KA.day) + 1 : nil

        // Reviving: after hooch or leaving the fridge, until "It doubled".
        let reviveTriggers = life.filter {
            if case .reported(.liquidOnTop) = $0.kind { return true }
            return $0.kind == .movedToCounter
        }.map(\.at)
        let isReviving = reviveTriggers.last.map { trigger in
            !doubledTimes.contains { $0 > trigger }
        } ?? false
        let isLongRevival = isReviving && life.contains { $0.kind == .reported(.liquidOnTop(heavy: true)) }

        // Ratio of the last feeding (flour ÷ starter kept).
        var ratio: Double?
        var lastFeedFlour = 0.0, lastFeedWater = 0.0
        if let i = feedIndex, case .fed(let kept, let flour, let water) = life[i].kind {
            lastFeedFlour = flour
            lastFeedWater = water
            ratio = kept > 0 ? flour / kept : .infinity
        }
        let fedBelowMinimum = (ratio.map { ($0 * 10).rounded() / 10 < 1 }) ?? false

        // Thirsty: less water than flour, or "dry" reported and no water added since.
        let dryReport = reportsSinceFeed.last { $0.1 == .dryOrThick }?.0
        let waterAddedAfterDry = dryReport.map { report in
            sinceFeed.contains { event in
                if case .addedWater = event.kind { return event.at >= report }
                return false
            }
        } ?? false
        let thirsty = lastFeedWater < lastFeedFlour || (dryReport != nil && !waterAddedAfterDry)

        // --- Timings ---

        let interval: TimeInterval
        if isInFridge {
            interval = KA.fridgeInterval
        } else if let day = babyDay {
            interval = KA.babyInterval(day: day)
        } else {
            interval = schedule.interval
        }
        let nextFeedDue = fedAt.addingTimeInterval(interval)

        // Peak window from KA's ratio test. Never fed in this life → treat as 1:1:1 estimate.
        let tested = ratio.map(TestedRatio.nearest) ?? .oneToOne
        let isEstimate = ratio.map { !TestedRatio.isTested($0) } ?? true
        let peakedAt = reportsSinceFeed.last { $0.1 == .peaked }?.0

        let readyAt = peakedAt ?? fedAt.addingTimeInterval(tested.readyAfter)
        let hungryAt: Date
        if let fallsAfter = tested.fallsAfter {
            // 1:1:1: falls (fallsAfter - readyAfter) after peak. Shift it if "It peaked" was tapped.
            hungryAt = readyAt.addingTimeInterval(fallsAfter - tested.readyAfter)
        } else {
            // No KA fall time: Hungry at the first scheduled feeding after it peaks.
            var due = nextFeedDue
            while due <= readyAt { due += interval }
            hungryAt = due
        }

        // --- Pick the face (same order as STARTER_RULES.md) ---

        let face: Face
        if spoiled {
            face = .spoiled
        } else if starving {
            face = .starving
        } else if isInFridge {
            face = now < nextFeedDue ? .sleepy : .hungry
        } else if isBaby {
            face = .baby
        } else if thirsty {
            face = .thirsty
        } else if now < readyAt {
            face = .rising
        } else if now < hungryAt {
            face = .ready
        } else {
            face = .hungry
        }

        return StarterStatus(
            face: face,
            readyAt: isInFridge ? nil : readyAt,
            hungryAt: isInFridge ? nil : hungryAt,
            isEstimate: isEstimate,
            nextFeedDue: nextFeedDue,
            isReviving: isReviving,
            isLongRevival: isLongRevival,
            fedBelowMinimum: fedBelowMinimum,
            babyDay: babyDay
        )
    }
}
