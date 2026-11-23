import Foundation
import Testing
@testable import SourdoughCore

// A fixed "now" so tests always give the same answer.
private let now = Date(timeIntervalSince1970: 1_800_000_000)
private func hoursAgo(_ h: Double) -> Date { now.addingTimeInterval(-h * 3600) }

private func starter() -> Dough {
    Dough(name: "Bubbles", type: .starter, grams: 100, startedAt: hoursAgo(12))
}

private func pizza() -> Dough {
    Dough(name: "Saturday pizza", type: .pizza, grams: 1000, startedAt: hoursAgo(2))
}

@Test func storesItsValues() {
    let dough = starter()
    #expect(dough.name == "Bubbles")
    #expect(dough.type == .starter)
    #expect(dough.grams == 100)
    #expect(dough.lastFed == hoursAgo(12)) // never fed → when it started
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

@Test func feedingCanDiscardFirst() throws {
    var dough = starter()
    try dough.feed(flour: 50, water: 50, keeping: 50, at: now) // KA: keep 50, add 50 + 50
    #expect(dough.grams == 150)
}

@Test func cannotKeepMoreThanIsInTheJar() {
    var dough = starter()
    #expect(throws: DoughError.cannotKeepMoreThanInJar) {
        try dough.feed(flour: 50, water: 50, keeping: 500, at: now)
    }
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
    s.takeOut(30, at: now)
    #expect(s.grams == 70)

    var p = pizza()
    p.takeOut(5000, reason: .bake, at: now)
    #expect(p.grams == 0)
}

@Test func fridgeMovesAreTracked() {
    var s = starter()
    s.moveToFridge(at: hoursAgo(2))
    #expect(s.isInFridge)
    s.moveToCounter(at: now)
    #expect(!s.isInFridge)
}

@Test func undoRemovesTheLastEvent() throws {
    var s = starter()
    try s.feed(flour: 50, water: 50, at: now)
    s.undoLast()
    #expect(s.grams == 100)
    s.undoLast() // can't remove the starting event
    #expect(s.events.count == 1)
}

@Test func eventsLoadInTimeOrder() {
    let late = JarEvent(at: now, kind: .addedWater(grams: 10))
    let early = JarEvent(at: hoursAgo(5), kind: .started(grams: 100, isNewStarter: false))
    let dough = Dough(id: UUID(), name: "Loaded", type: .starter, schedule: .every12Hours,
                      createdAt: hoursAgo(5), events: [late, early])
    #expect(dough.grams == 110)
}

@Test func roundTripsThroughJSON() throws {
    var s = starter()
    try s.feed(flour: 50, water: 50, keeping: 50, at: now)
    s.report(.liquidOnTop(heavy: true), at: now)
    let data = try JSONEncoder().encode(s)
    let back = try JSONDecoder().decode(Dough.self, from: data)
    #expect(back.events == s.events)
}
