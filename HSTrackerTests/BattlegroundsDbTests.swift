//
//  BattlegroundsDbTests.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/21/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import XCTest
@testable import HSTracker

// Ports HDT's BattlegroundsDbTest: the meta period, not the card data, decides
// which tribes the minion browser offers.
class BattlegroundsDbTests: HSTrackerTests {
    static var database: Database!

    // A tribe that is definitely in the card data, so leaving it out of the
    // meta period below is the only reason it could be missing from Races.
    private static let tribeInCardData = Race.naga

    private static var periodWithoutTheTribe: MetaPeriod {
        MetaPeriod(period_start: 0, mechanics: [], tag_overrides: nil,
                   minion_types: [Race.lookup(.beast), Race.lookup(.murloc)])
    }

    override class func setUp() {
        super.setUp()
        database = Database()
        database.loadDatabase(splashscreen: nil, withLanguages: [.enUS])
    }

    func testTribeMissingFromTheMetaPeriodIsNotInRacesButItsMinionsStayReachable() {
        let db = BattlegroundsDb(Self.periodWithoutTheTribe)

        XCTAssertEqual(db.races, Set<Race>([.beast, .murloc, .invalid, .all]))
        XCTAssertFalse(db.races.contains(Self.tribeInCardData))
        XCTAssertFalse(db.getCardsByRaces([Self.tribeInCardData], false).isEmpty)
    }

    func testRacesFallBackToTheCardDataWithoutAMetaPeriod() {
        let db = BattlegroundsDb(nil)

        XCTAssertTrue(db.races.contains(Self.tribeInCardData))
    }
}
