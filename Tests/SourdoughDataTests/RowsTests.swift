// Checks that every kind of event survives Core → database row → Core unchanged.
// No network needed.

import Foundation
import Testing
@testable import SourdoughCore
@testable import SourdoughData

private let now = Date(timeIntervalSince1970: 1_800_000_000)

@Test func everyEventKindRoundTrips() throws {
    let kinds: [JarEvent.Kind] = [
        .started(grams: 100, isNewStarter: true),
        .fed(kept: 50, flour: 50, water: 50),
        .tookOut(grams: 30, reason: .bake),
        .addedWater(grams: 15),
        .movedToFridge,
        .movedToCounter,
        .reported(.liquidOnTop(heavy: true)),
        .reported(.dryOrThick),
        .reported(.pinkStreaks),
        .reported(.peaked),
        .reported(.doubled),
    ]
    let jarId = UUID()
    for kind in kinds {
        let event = JarEvent(at: now, kind: kind)
        #expect(try EventRow(event, jarId: jarId).toEvent() == event)
    }
}

@Test func jarRoundTripsWithItsEvents() throws {
    var dough = Dough(name: "Bubbles", type: .starter, grams: 100, schedule: .every24Hours, startedAt: now)
    try dough.feed(flour: 50, water: 50, keeping: 50, at: now.addingTimeInterval(60))

    var row = JarRow(dough)
    row.jarEvents = dough.events.map { EventRow($0, jarId: dough.id) }
    let back = try row.toDough()

    #expect(back.id == dough.id)
    #expect(back.schedule == .every24Hours)
    #expect(back.events == dough.events)
    #expect(back.grams == 150)
}

@Test func usesTheDatabaseColumnNames() throws {
    let row = EventRow(JarEvent(at: now, kind: .started(grams: 100, isNewStarter: false)), jarId: UUID())
    let json = String(decoding: try JSONEncoder().encode(row), as: UTF8.self)
    #expect(json.contains("\"jar_id\""))
    #expect(json.contains("\"is_new_starter\""))
}

@Test func unknownKindIsReportedNotCrashed() {
    let row = EventRow(id: UUID(), jarId: UUID(), at: now, kind: "danced")
    #expect(throws: UnreadableRow.self) { try row.toEvent() }
}

@Test func jarWithoutStartIsRejected() {
    let row = JarRow(id: UUID(), name: "X", type: "starter", scheduleHours: 12, createdAt: now, jarEvents: [])
    #expect(throws: UnreadableRow.self) { try row.toDough() }
}
