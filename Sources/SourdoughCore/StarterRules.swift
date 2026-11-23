/*
Every number King Arthur Baking gives us, in one place.
If a number isn't here, KA doesn't give it and the app must not guess.
Full sources: STARTER_RULES.md
*/

import Foundation

/// How often a counter starter gets fed. Picked per jar.
public enum FeedingSchedule: Int, Codable, Sendable, CaseIterable {
    /// KA-maintain: "feed your room-temperature starter twice a day"
    case every12Hours = 12
    /// KA-feed: "Feed once a day, about every 24 hours"
    case every24Hours = 24

    public var interval: TimeInterval { TimeInterval(rawValue) * 3600 }
}

enum KA {
    static let hour: TimeInterval = 3600
    static let day: TimeInterval = 24 * hour

    /// KA-feed: refrigerated starter is fed "about once a week".
    static let fridgeInterval: TimeInterval = 7 * day

    /// KA-create: days 1–2 feed every 24 h, from day 3 every 12 h.
    static func babyInterval(day: Int) -> TimeInterval {
        day <= 2 ? 24 * hour : 12 * hour
    }
}

/// The three feeding ratios King Arthur actually timed (KA-ratios, ~78°F).
/// "1:2:2" = 1 part starter kept : 2 parts flour : 2 parts water.
enum TestedRatio: Double, CaseIterable {
    case oneToOne = 1
    case oneToTwo = 2
    case oneToFour = 4

    /// Hours after feeding until it's at peak.
    var readyAfter: TimeInterval {
        switch self {
        case .oneToOne: 4 * KA.hour    // "doubled by 4 hours"
        case .oneToTwo: 8 * KA.hour    // "peaked at 8 hours"
        case .oneToFour: 12 * KA.hour  // "peaked by 12 hours"
        }
    }

    /// Hours after feeding until it starts falling. Only KA's 1:1:1 test says.
    var fallsAfter: TimeInterval? {
        switch self {
        case .oneToOne: 8 * KA.hour    // "starting to fall by 8 hours"
        case .oneToTwo, .oneToFour: nil
        }
    }

    /// Nearest tested ratio (STARTER_RULES.md: <1.5, 1.5..<3, 3+).
    static func nearest(to ratio: Double) -> TestedRatio {
        if ratio < 1.5 { return .oneToOne }
        if ratio < 3 { return .oneToTwo }
        return .oneToFour
    }

    /// True when the ratio (to one decimal) is exactly one KA tested.
    static func isTested(_ ratio: Double) -> Bool {
        let rounded = (ratio * 10).rounded() / 10
        return allCases.contains { $0.rawValue == rounded }
    }
}
