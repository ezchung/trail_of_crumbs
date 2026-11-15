import Foundation
import Testing
@testable import SourdoughCore

// A fixed "now" so tests always give the same answer.
private let now = Date(timeIntervalSince1970: 1_800_000_000)
private func hoursAgo(_ h: Double) -> Date { now.addingTimeInterval(-h * 3600) }

private func starter() -> Dough {
    Dough(name: "Bubbles", type: .starter, grams: 100, lastFed: hoursAgo(12), createdAt: hoursAgo(24 * 30))
}

private func pizza() -> Dough {
    Dough(name: "Saturday pizza", type: .pizza, grams: 1000, lastFed: hoursAgo(2), createdAt: hoursAgo(2))
}

@Test func storesItsValues() {
    let dough = starter()
    #expect(dough.name == "Bubbles")
    #expect(dough.type == .starter)
    #expect(dough.grams == 100)
}

@Test func onlyStarterIsAStarter() {
    #expect(DoughType.starter.isStarter)
    #expect(!DoughType.bread.isStarter)
    #expect(!DoughType.pizza.isStarter)
}

@Test func feedingAStarterAddsGramsAndResetsTimer() throws {
    var dough = starter()
    try dough.feed(flour: 50, water: 50, at: now)
    #expect(dough.grams == 200)
    #expect(dough.lastFed == now)
}

@Test func doughCannotBeFed() {
    var dough = pizza()
    #expect(throws: DoughError.onlyStartersCanBeFed) {
        try dough.feed(flour: 50, water: 50, at: now)
    }
    #expect(dough.grams == 1000) // unchanged
}

@Test func takingOutWorksForBothAndNeverGoesNegative() {
    var s = starter()
    s.takeOut(30)
    #expect(s.grams == 70)

    var p = pizza()
    p.takeOut(5000)
    #expect(p.grams == 0)
}
