//
//  StatsTests.swift
//  HSTracker
//
//  Created by Matthew Welborn on 6/9/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import XCTest
import Foundation
import RealmSwift

@testable import HSTracker

class StatsTests: HSTrackerTests {

    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }

    func testErfinv() {
        let values: [[Double]] = [
            [0.91315112686 , 1.21075024057],
            [0.582751704807 , 0.573608137167],
            [0.718243287706 , 0.761116595129],
            [0.00856985966945 , 0.00759498641983],
            [0.51475402072 , 0.493482762145]]
        for i in 0...values.count-1 {
            XCTAssert(fuzzyFloatEquals(a: StatsHelper.erfinv(y: values[i][0]), b: values[i][1]))
        }
    }
    
    func testBinomialProportionConfidenceInterval() {
        let correct_lower = 0.5838606324
        let correct_upper = 0.7914774104
        let results = StatsHelper.binomialProportionCondifenceInterval(wins: 30,
                                                                       losses: 13,
                                                                       confidence: 0.87)

        XCTAssert(fuzzyFloatEquals(a: results.lower, b: correct_lower))
        XCTAssert(fuzzyFloatEquals(a: results.upper, b: correct_upper))
    }
    
    private func fuzzyFloatEquals(a: Double, b: Double) -> Bool {
        let closeEnough = 1e-4
        return abs(a-b) < closeEnough
    }
    
    private func makeDeck(name: String, in realm: Realm,
                          results: [(GameResult, GameMode)]) throws -> Deck {
        let deck = Deck()
        deck.name = name
        for (result, mode) in results {
            let stat = GameStats()
            stat.statId = generateId()
            stat.result = result
            stat.gameMode = mode
            deck.gameStats.append(stat)
        }
        try realm.write {
            realm.add(deck)
        }
        return deck
    }

    func testGetDeckRecordCountsEveryMode() throws {
        let realm = try Realm()
        let deck = try makeDeck(name: "Mixed", in: realm, results: [
            (.win, .ranked), (.win, .ranked), (.loss, .ranked),
            (.win, .casual), (.draw, .casual),
            (.unknown, .ranked)
        ])

        let all = StatsHelper.getDeckRecord(deck: deck, mode: .all)
        XCTAssertEqual(all.wins, 3)
        XCTAssertEqual(all.losses, 1)
        XCTAssertEqual(all.draws, 1)
        // The unknown result is counted by neither, as before.
        XCTAssertEqual(all.total, 5)

        let ranked = StatsHelper.getDeckRecord(deck: deck, mode: .ranked)
        XCTAssertEqual(ranked.wins, 2)
        XCTAssertEqual(ranked.losses, 1)
        XCTAssertEqual(ranked.draws, 0)
        XCTAssertEqual(ranked.total, 3)
    }

    /// The deck manager reads the records on a background queue, which means
    /// opening a second Realm there. Realm objects cannot cross threads, so
    /// this checks the lookup really does happen on the far side and that only
    /// values come back.
    func testGetDeckRecordsOffTheMainThread() throws {
        let realm = try Realm()
        let winning = try makeDeck(name: "Winning", in: realm, results: [
            (.win, .ranked), (.win, .ranked), (.win, .casual), (.loss, .ranked)
        ])
        let losing = try makeDeck(name: "Losing", in: realm, results: [
            (.loss, .ranked), (.loss, .casual), (.win, .ranked)
        ])
        let deckIds = [winning.deckId, losing.deckId]

        let expectation = self.expectation(description: "records computed off the main thread")
        var records: [String: StatsDeckRecord]?

        DispatchQueue.global(qos: .userInitiated).async {
            XCTAssertFalse(Thread.isMainThread)
            records = StatsHelper.getDeckRecords(deckIds: deckIds, mode: .all)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 10)

        guard let records = records else {
            XCTFail("no records were computed")
            return
        }
        XCTAssertEqual(records.count, 2)
        XCTAssertEqual(records[winning.deckId]?.wins, 3)
        XCTAssertEqual(records[winning.deckId]?.losses, 1)
        XCTAssertEqual(records[losing.deckId]?.wins, 1)
        XCTAssertEqual(records[losing.deckId]?.losses, 2)
    }

    func testGetDeckRecordsSkipsUnknownDecks() throws {
        // The realm has to stay open for the duration: an in-memory realm is
        // discarded as soon as the last instance goes away.
        let realm = try Realm()
        try withExtendedLifetime(realm) {
            let records = StatsHelper.getDeckRecords(deckIds: ["not-a-deck"], mode: .all)
            XCTAssertTrue(records.isEmpty)
        }
    }

    func testSQL() {
        let lg = LadderGrid()
        guard let games = lg.getGamesToRank(targetRank: 5, stars: 0, bonus: 2 , winp: 0.655) else {
            XCTFail("failed to calculate games")
            return
        }
        XCTAssertGreaterThan(games, 100)
    }
}
