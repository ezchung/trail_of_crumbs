/*
This is the dough: the data behind every jar on the shelf.
The jar is only the look; it reads a Dough and draws it.

Starter vs dough:
- A starter lives on forever: you feed it and take some out.
- A dough (bread, pizza) is mixed once and used up. It can't be fed.
Both are the same `Dough` type, so the shelf is one list and every jar works the same.
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
}

public struct Dough: Codable, Sendable {
    public var name: String
    public var type: DoughType
    public var grams: Double
    public var lastFed: Date
    public var createdAt: Date

    public init(name: String, type: DoughType, grams: Double, lastFed: Date, createdAt: Date) {
        self.name = name
        self.type = type
        self.grams = grams
        self.lastFed = lastFed
        self.createdAt = createdAt
    }

    /// Add flour + water to a starter. Grams go up and the timer resets.
    public mutating func feed(flour: Double, water: Double, at now: Date) throws {
        guard type.isStarter else { throw DoughError.onlyStartersCanBeFed }
        grams += flour + water
        lastFed = now
    }

    /// Take some out (for a bake, discard...). Works for every type. Never goes below 0.
    public mutating func takeOut(_ amount: Double) {
        grams = max(0, grams - amount)
    }
}
