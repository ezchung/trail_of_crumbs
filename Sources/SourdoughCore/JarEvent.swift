/*
A jar's history is a list of events: everything you ever did to it.

The jar never stores "grams" or "face" directly. Both are worked out by
replaying these events (see Dough.swift and StarterStatus.swift). That gives:
- the Journal's History for free (it's just this list),
- undo for free (drop the last event),
- one source of truth, so grams and face can never disagree.
*/

import Foundation

public struct JarEvent: Codable, Sendable, Equatable, Identifiable {
    public var id: UUID
    public var at: Date
    public var kind: Kind

    public init(id: UUID = UUID(), at: Date, kind: Kind) {
        self.id = id
        self.at = at
        self.kind = kind
    }

    public enum Kind: Codable, Sendable, Equatable {
        /// The jar starts (or restarts) with this many grams.
        /// `isNewStarter` = true starts a Baby starter from scratch.
        case started(grams: Double, isNewStarter: Bool)

        /// Keep `kept` grams (the rest is discarded), then add flour + water.
        case fed(kept: Double, flour: Double, water: Double)

        /// Some taken out, e.g. for a bake or discard.
        case tookOut(grams: Double, reason: TakeOutReason)

        /// Water stirred in to fix a dry / thick starter (KA: 1–2 tbsp at a time).
        case addedWater(grams: Double)

        case movedToFridge
        case movedToCounter

        /// Something you saw. The app can't look in the jar, so you tell it.
        case reported(Report)
    }
}

public enum TakeOutReason: String, Codable, Sendable {
    case bake, discard, gaveAway
}

/// Things only a person can see. Each one changes the face (STARTER_RULES.md).
public enum Report: Codable, Sendable, Equatable {
    /// Hooch. `heavy` = lots of liquid or very dark (KA: slower to revive).
    case liquidOnTop(heavy: Bool)
    case dryOrThick
    case pinkStreaks
    /// "It peaked": Ready starts now, overriding the estimate.
    case peaked
    /// "It doubled": a Baby is grown up / a reviving starter is healthy again.
    case doubled
}
