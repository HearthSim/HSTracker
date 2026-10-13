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

    func testKeywordSpellsIncludeDuosExclusiveSpellsOnlyInDuos() throws {
        let db = BattlegroundsDb(nil)
        let duosSpell = try XCTUnwrap(Cards.cards.first {
            $0.type == .battleground_spell && $0.isBaconPoolSpell && $0.isBaconDuosExclusive > 0 && !$0.enText.isEmpty
        }, "no Duos-exclusive spell in the card data")
        // HDT matches every pool spell with TagKeyword(TECH_LEVEL, ""); a
        // mention of the spell's own text is the nearest keyword Swift can build
        let keyword = BattlegroundsKeyword(locKey: "", englishName: duosSpell.enText, mechanic: nil)

        XCTAssertTrue(db.getSpells(keyword: keyword, true).contains { $0.dbfId == duosSpell.dbfId })
        XCTAssertFalse(db.getSpells(keyword: keyword, false).contains { $0.dbfId == duosSpell.dbfId })
    }

    private static func periodWithTavernPool(_ dbfIds: Int...) -> MetaPeriod {
        MetaPeriod(period_start: 0, mechanics: [], tag_overrides: nil, minion_types: nil,
                   tavern_pool: dbfIds.map { CardInfo(dbf_id: $0) })
    }

    func testTavernPoolOnlyListsItsCardsRegardlessOfGameModeExclusivity() throws {
        let assembled = BattlegroundsDb(nil)
        // Dark Paradox never comes from the tavern pool list (BattlegroundsDb
        // leaves it out on purpose), so it can't be the listed minion.
        let darkParadox = Cards.any(byId: CardIds.NonCollectible.Neutral.DarkParadox)?.dbfId
        let poolMinions = assembled.getCardsByRaces(Array(assembled.races), false)
            .filter { $0.dbfId != darkParadox && $0.baconEvolutionCardId != darkParadox }
        let listedMinion = try XCTUnwrap(poolMinions.first)
        let unlistedMinion = try XCTUnwrap(poolMinions.first { $0.dbfId != listedMinion.dbfId })
        let duosMinion = try XCTUnwrap(Cards.cards.first {
            $0.type == .minion && $0.techLevel > 0 && $0.isBaconPoolMinion == 1 && $0.isBaconDuosExclusive > 0
        }, "no Duos-exclusive minion in the card data")
        let spell = try XCTUnwrap(assembled.getSpells(false).first)

        let db = BattlegroundsDb(Self.periodWithTavernPool(listedMinion.dbfId, duosMinion.dbfId, spell.dbfId))

        let minions = db.getCardsByRaces(Array(db.races), false).map { $0.dbfId }
        XCTAssertEqual(Set(minions), Set([listedMinion.dbfId, duosMinion.dbfId]))
        XCTAssertFalse(minions.contains(unlistedMinion.dbfId))
        XCTAssertEqual(Set(db.getSpells(false).map { $0.dbfId }), [spell.dbfId])
    }

    func testTavernPoolWithoutAKnownMinionFallsBackToTheCardData() throws {
        let assembled = BattlegroundsDb(nil)
        let assembledMinions = Set(assembled.getCardsByRaces(Array(assembled.races), false).map { $0.dbfId })
        let spell = try XCTUnwrap(assembled.getSpells(false).first)

        for period in [Self.periodWithTavernPool(), Self.periodWithTavernPool(spell.dbfId, Int.max)] {
            let db = BattlegroundsDb(period)

            XCTAssertEqual(Set(db.getCardsByRaces(Array(db.races), false).map { $0.dbfId }), assembledMinions)
            XCTAssertEqual(Set(db.getSpells(false).map { $0.dbfId }), Set(assembled.getSpells(false).map { $0.dbfId }))
        }
    }
}
