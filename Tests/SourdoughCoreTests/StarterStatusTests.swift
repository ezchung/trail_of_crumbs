// One test per row of the Faces table in STARTER_RULES.md, plus timing rules.

import Foundation
import Testing
@testable import SourdoughCore

private let now = Date(timeIntervalSince1970: 1_800_000_000)
private func hoursAgo(_ h: Double) -> Date { now.addingTimeInterval(-h * 3600) }
private func daysAgo(_ d: Double) -> Date { hoursAgo(d * 24) }

/// An adult starter fed 1:1:1 (50 kept + 50 flour + 50 water) `h` hours ago.
private func fed(hoursAgo h: Double, schedule: FeedingSchedule = .every12Hours) -> Dough {
    var d = Dough(name: "Bubbles", type: .starter, grams: 100, schedule: schedule, startedAt: daysAgo(30))
    try! d.feed(flour: 50, water: 50, keeping: 50, at: hoursAgo(h))
    return d
}

private func face(_ d: Dough) -> Face? { d.starterStatus(at: now)?.face }

// MARK: - Rising / Ready / Hungry (1:1:1, KA-ratios)

@Test func risingBeforeFourHours() { #expect(face(fed(hoursAgo: 2)) == .rising) }
@Test func readyFromFourToEightHours() {
    #expect(face(fed(hoursAgo: 4)) == .ready)
    #expect(face(fed(hoursAgo: 7.9)) == .ready)
}
@Test func hungryFromEightHours() { #expect(face(fed(hoursAgo: 8)) == .hungry) }

@Test func exactTestedRatioIsNotAnEstimate() {
    #expect(fed(hoursAgo: 1).starterStatus(at: now)?.isEstimate == false)
}

// MARK: - Other ratios

@Test func oneToTwoPeaksAtEightAndIsHungryWhenDue() throws {
    var d = Dough(name: "B", type: .starter, grams: 100, startedAt: daysAgo(30))
    try d.feed(flour: 100, water: 100, keeping: 50, at: hoursAgo(9)) // 1:2:2
    let s = try #require(d.starterStatus(at: now))
    #expect(s.face == .ready)
    #expect(s.readyAt == hoursAgo(1))
    #expect(s.hungryAt == hoursAgo(9).addingTimeInterval(12 * 3600)) // next feeding due
    #expect(!s.isEstimate)
}

@Test func oneToFourOnTwelveHourScheduleStaysReadyUntilTheFollowingFeeding() throws {
    var d = Dough(name: "B", type: .starter, grams: 100, startedAt: daysAgo(30))
    try d.feed(flour: 80, water: 80, keeping: 20, at: hoursAgo(13)) // 1:4:4, peaks at 12 h
    let s = try #require(d.starterStatus(at: now))
    #expect(s.face == .ready)
    #expect(s.hungryAt == hoursAgo(13).addingTimeInterval(24 * 3600))
}

@Test func untestedRatioUsesNearestAndIsAnEstimate() throws {
    var d = Dough(name: "B", type: .starter, grams: 100, startedAt: daysAgo(30))
    try d.feed(flour: 75, water: 75, keeping: 50, at: hoursAgo(5)) // 1:1.5 → nearest 1:2:2
    let s = try #require(d.starterStatus(at: now))
    #expect(s.isEstimate)
    #expect(s.face == .rising) // 1:2:2 peaks at 8 h
}

@Test func belowOneToOneIsFlagged() throws {
    var d = Dough(name: "B", type: .starter, grams: 100, startedAt: daysAgo(30))
    try d.feed(flour: 25, water: 25, keeping: 50, at: hoursAgo(1))
    let s = try #require(d.starterStatus(at: now))
    #expect(s.fedBelowMinimum)
    #expect(s.isEstimate)
}

@Test func itPeakedTapStartsReadyNow() throws {
    var d = fed(hoursAgo: 2) // would still be Rising
    d.report(.peaked, at: hoursAgo(0.5))
    let s = try #require(d.starterStatus(at: now))
    #expect(s.face == .ready)
    #expect(s.hungryAt == hoursAgo(0.5).addingTimeInterval(4 * 3600))
}

// MARK: - Schedule

@Test func nextFeedFollowsTheJarsSchedule() {
    #expect(fed(hoursAgo: 1).starterStatus(at: now)?.nextFeedDue == hoursAgo(1).addingTimeInterval(12 * 3600))
    #expect(fed(hoursAgo: 1, schedule: .every24Hours).starterStatus(at: now)?.nextFeedDue
            == hoursAgo(1).addingTimeInterval(24 * 3600))
}

// MARK: - Fridge (KA-feed: weekly)

@Test func sleepyInFridgeUnderAWeek() {
    var d = fed(hoursAgo: 48)
    d.moveToFridge(at: hoursAgo(46))
    #expect(face(d) == .sleepy)
    #expect(d.starterStatus(at: now)?.readyAt == nil)
}

@Test func hungryInFridgeAfterAWeek() {
    var d = fed(hoursAgo: 8 * 24)
    d.moveToFridge(at: hoursAgo(8 * 24 - 2))
    #expect(face(d) == .hungry)
}

@Test func outOfFridgeIsReviving() {
    var d = fed(hoursAgo: 72)
    d.moveToFridge(at: hoursAgo(70))
    d.moveToCounter(at: hoursAgo(1))
    let s = d.starterStatus(at: now)
    #expect(s?.face == .hungry)
    #expect(s?.isReviving == true)
}

// MARK: - Reports

@Test func liquidOnTopIsStarvingUntilFed() throws {
    var d = fed(hoursAgo: 30)
    d.report(.liquidOnTop(heavy: false), at: hoursAgo(1))
    #expect(face(d) == .starving)

    try d.feed(flour: 50, water: 50, keeping: 50, at: hoursAgo(0.5))
    let s = try #require(d.starterStatus(at: now))
    #expect(s.face == .rising)
    #expect(s.isReviving)
    #expect(!s.isLongRevival)
}

@Test func heavyHoochMeansLongRevival() {
    var d = fed(hoursAgo: 30)
    d.report(.liquidOnTop(heavy: true), at: hoursAgo(1))
    #expect(d.starterStatus(at: now)?.isLongRevival == true)
}

@Test func doubledEndsReviving() throws {
    var d = fed(hoursAgo: 30)
    d.report(.liquidOnTop(heavy: false), at: hoursAgo(20))
    try d.feed(flour: 50, water: 50, keeping: 50, at: hoursAgo(10))
    d.report(.doubled, at: hoursAgo(3))
    #expect(d.starterStatus(at: now)?.isReviving == false)
}

@Test func pinkStreaksAreSpoiledEvenAfterFeeding() throws {
    var d = fed(hoursAgo: 5)
    d.report(.pinkStreaks, at: hoursAgo(1))
    try d.feed(flour: 50, water: 50, keeping: 50, at: now)
    #expect(face(d) == .spoiled)
}

@Test func restartClearsSpoiled() {
    var d = fed(hoursAgo: 5)
    d.report(.pinkStreaks, at: hoursAgo(1))
    d.restart(grams: 100, asNewStarter: true, at: now)
    #expect(face(d) == .baby)
}

@Test func lessWaterThanFlourIsThirsty() throws {
    var d = Dough(name: "B", type: .starter, grams: 100, startedAt: daysAgo(30))
    try d.feed(flour: 50, water: 40, keeping: 50, at: hoursAgo(1))
    #expect(face(d) == .thirsty)
}

@Test func dryReportIsThirstyUntilWaterAdded() {
    var d = fed(hoursAgo: 1)
    d.report(.dryOrThick, at: hoursAgo(0.5))
    #expect(face(d) == .thirsty)
    d.addWater(15, at: hoursAgo(0.25))
    #expect(face(d) == .rising)
}

// MARK: - Baby (KA-create)

@Test func newStarterIsBabyWithDayCount() throws {
    let d = Dough(name: "Tiny", type: .starter, grams: 100, isNewStarter: true, startedAt: daysAgo(2.5))
    let s = try #require(d.starterStatus(at: now))
    #expect(s.face == .baby)
    #expect(s.babyDay == 3)
}

@Test func babyFeedsDailyThenTwiceADay() throws {
    var d = Dough(name: "Tiny", type: .starter, grams: 100, isNewStarter: true, startedAt: hoursAgo(10))
    #expect(d.starterStatus(at: now)?.nextFeedDue == hoursAgo(10).addingTimeInterval(24 * 3600)) // day 1

    d = Dough(name: "Tiny", type: .starter, grams: 100, isNewStarter: true, startedAt: daysAgo(3))
    try d.feed(flour: 50, water: 50, keeping: 50, at: hoursAgo(1))
    #expect(d.starterStatus(at: now)?.nextFeedDue == hoursAgo(1).addingTimeInterval(12 * 3600)) // day 4
}

@Test func babyGrowsUpWhenItDoubles() throws {
    var d = Dough(name: "Tiny", type: .starter, grams: 100, isNewStarter: true, startedAt: daysAgo(5))
    try d.feed(flour: 50, water: 50, keeping: 50, at: hoursAgo(5))
    d.report(.doubled, at: hoursAgo(0.5))
    let s = try #require(d.starterStatus(at: now))
    #expect(s.face == .ready)
    #expect(s.babyDay == nil)
}

// MARK: - Order of checks

@Test func starvingBeatsFridge() {
    var d = fed(hoursAgo: 48)
    d.moveToFridge(at: hoursAgo(46))
    d.report(.liquidOnTop(heavy: false), at: now)
    #expect(face(d) == .starving)
}

@Test func doughJarsHaveNoStarterFaceYet() {
    let p = Dough(name: "Pizza", type: .pizza, grams: 1000, startedAt: hoursAgo(1))
    #expect(p.starterStatus(at: now) == nil)
}
