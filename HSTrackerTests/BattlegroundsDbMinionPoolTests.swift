//
//  BattlegroundsDbMinionPoolTests.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/24/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import XCTest
@testable import HSTracker

// Ports HDT's BattlegroundsDbMinionPoolTest: a database built from the pool the
// game server sent for the match.
class BattlegroundsDbMinionPoolTests: HSTrackerTests {
    static var database: Database!
    static var fallback: BattlegroundsDb!

    override class func setUp() {
        super.setUp()
        database = Database()
        database.loadDatabase(splashscreen: nil, withLanguages: [.enUS])
        fallback = BattlegroundsDb(nil)
    }

    private var fallback: BattlegroundsDb { Self.fallback }

    private func minion(_ dbfId: Int, _ tier: Int, _ races: Race..., banned: Bool = false) -> MirrorBattlegroundsMinionPoolEntry {
        let entry = MirrorBattlegroundsMinionPoolEntry()
        entry.dbfId = dbfId
        entry.tier = tier
        entry.cardType = CardType.minion.rawValue
        entry.minionTypes = races.map { NSNumber(value: Race.lookup($0)) }
        entry.banned = banned
        return entry
    }

    private func spell(_ dbfId: Int, _ tier: Int, banned: Bool = false) -> MirrorBattlegroundsMinionPoolEntry {
        let entry = MirrorBattlegroundsMinionPoolEntry()
        entry.dbfId = dbfId
        entry.tier = tier
        entry.cardType = CardType.battleground_spell.rawValue
        entry.minionTypes = []
        entry.banned = banned
        return entry
    }

    private func pool(_ activeRaces: [Race], _ cards: MirrorBattlegroundsMinionPoolEntry...) -> MirrorBattlegroundsMinionPool {
        let pool = MirrorBattlegroundsMinionPool()
        pool.cards = cards
        pool.activeMinionTypes = activeRaces.map { NSNumber(value: Race.lookup($0)) }
        return pool
    }

    func testPoolFilesCardsUnderTheServerTierAndMinionTypes() throws {
        let beast = try XCTUnwrap(fallback.getCards(1, .beast, false).first)
        let neutral = try XCTUnwrap(fallback.getCards(2, .invalid, false).first)
        let leftOut = try XCTUnwrap(fallback.getCards(1, .beast, false).first { $0.dbfId != beast.dbfId })
        let spell = try XCTUnwrap(fallback.getSpells(1, false).first)

        let db = BattlegroundsDb.fromMinionPool(pool(
            [.beast],
            minion(beast.dbfId, 3, .beast),
            minion(neutral.dbfId, 2, .invalid),
            self.spell(spell.dbfId, 4)
        ), fallback: fallback)

        XCTAssertTrue(db.getCards(3, .beast, false).contains { $0.dbfId == beast.dbfId })
        XCTAssertTrue(db.getCards(1, .beast, false).isEmpty)
        XCTAssertTrue(db.getCards(2, .invalid, false).contains { $0.dbfId == neutral.dbfId })
        XCTAssertEqual(db.getSpells(4, false).map { $0.dbfId }, [spell.dbfId])
        XCTAssertTrue(db.getSpells(1, false).isEmpty)

        let available = Set(db.getCardsByRaces([.beast, .invalid], false).map { $0.dbfId })
        XCTAssertEqual(available, [beast.dbfId, neutral.dbfId])
        XCTAssertFalse(available.contains(leftOut.dbfId))
    }

    func testBannedCardsAreShownFadedButAreNotAvailable() throws {
        let banned = try XCTUnwrap(fallback.getCards(1, .beast, false).first)
        let allowed = try XCTUnwrap(fallback.getCards(1, .beast, false).first { $0.dbfId != banned.dbfId })
        let bannedSpell = try XCTUnwrap(fallback.getSpells(1, false).first)

        let db = BattlegroundsDb.fromMinionPool(pool(
            [.beast],
            minion(banned.dbfId, 1, .beast, banned: true),
            minion(allowed.dbfId, 1, .beast),
            spell(bannedSpell.dbfId, 1, banned: true)
        ), fallback: fallback)

        // HDT checks the shown cards' Count; HSTracker's browser darkens
        // whatever isBanned reports instead
        let shown = db.getCards(1, .beast, false).map { $0.dbfId }
        XCTAssertTrue(shown.contains(banned.dbfId))
        XCTAssertTrue(shown.contains(allowed.dbfId))
        XCTAssertFalse(db.isBanned(allowed.dbfId))
        XCTAssertEqual(db.getSpells(1, false).map { $0.dbfId }, [bannedSpell.dbfId])
        XCTAssertTrue(db.isBanned(bannedSpell.dbfId))

        XCTAssertEqual(db.getCardsByRaces([.beast], false).map { $0.dbfId }, [allowed.dbfId])
        XCTAssertTrue(db.getSpells(false).isEmpty)
        XCTAssertTrue(db.isBanned(banned.dbfId))
    }

    func testPoolIgnoresDuosExclusivityAsTheServerAlreadySentTheModesPool() throws {
        let duosOnly = try XCTUnwrap(Cards.cards.first { $0.isBaconDuosExclusive > 0 && $0.isBaconPoolMinion == 1 },
                                     "no Duos-exclusive minion in the card data")

        let db = BattlegroundsDb.fromMinionPool(pool([.beast], minion(duosOnly.dbfId, 2, .invalid)), fallback: fallback)

        XCTAssertEqual(db.getCards(2, .invalid, false).map { $0.dbfId }, [duosOnly.dbfId])
        XCTAssertEqual(db.getCards(2, .invalid, true).map { $0.dbfId }, [duosOnly.dbfId])
    }

    func testMinionsAreAlsoListedUnderActiveTribesTheyAreASubsetOf() throws {
        let subsetMinion = try XCTUnwrap(Cards.cards.first {
            $0.baconSubsetRaces.contains(.murloc) && $0.race != .murloc && !$0.races.contains(.murloc)
        }, "no minion with a Murloc subset tag in the card data")

        let withMurlocs = BattlegroundsDb.fromMinionPool(pool([.murloc], minion(subsetMinion.dbfId, 3, .invalid)), fallback: fallback)
        let withoutMurlocs = BattlegroundsDb.fromMinionPool(pool([.beast], minion(subsetMinion.dbfId, 3, .invalid)), fallback: fallback)

        XCTAssertEqual(withMurlocs.getCards(3, .murloc, false).map { $0.dbfId }, [subsetMinion.dbfId])
        XCTAssertEqual(withMurlocs.getCards(3, .invalid, false).map { $0.dbfId }, [subsetMinion.dbfId])
        XCTAssertTrue(withoutMurlocs.getCards(3, .murloc, false).isEmpty)
    }

    func testDarkParadoxPrefersThisGamesVariantOverTheGenericCard() throws {
        let generic = try XCTUnwrap(Cards.any(byId: CardIds.NonCollectible.Neutral.DarkParadox))
        let variant = try XCTUnwrap(Cards.any(byId: CardIds.NonCollectible.Neutral.DarkParadox_DarkParadoxToken2))
        let beast = try XCTUnwrap(fallback.getCards(1, .beast, false).first)

        let withVariant = BattlegroundsDb.fromMinionPool(pool(
            [.beast],
            minion(generic.dbfId, 1, .invalid),
            minion(variant.dbfId, 5, .invalid),
            minion(beast.dbfId, 1, .beast)
        ), fallback: fallback)
        let genericOnly = BattlegroundsDb.fromMinionPool(pool([.beast], minion(generic.dbfId, 1, .invalid)), fallback: fallback)
        let without = BattlegroundsDb.fromMinionPool(pool([.beast], minion(beast.dbfId, 1, .beast)), fallback: fallback)
        let banned = BattlegroundsDb.fromMinionPool(pool([.beast], minion(variant.dbfId, 5, .invalid, banned: true)), fallback: fallback)

        XCTAssertEqual(withVariant.darkParadox?.dbfId, variant.dbfId)
        XCTAssertEqual(withVariant.darkParadoxTier, 5)
        XCTAssertEqual(genericOnly.darkParadox?.dbfId, generic.dbfId)
        XCTAssertNil(without.darkParadox)
        XCTAssertNil(without.darkParadoxTier)
        XCTAssertNil(banned.darkParadox)
    }

    func testRacesAndBuddiesComeFromTheFallback() throws {
        let db = BattlegroundsDb.fromMinionPool(pool([.beast]), fallback: fallback)

        XCTAssertTrue(fallback.races.isSubset(of: db.races))
        let buddyTier = try XCTUnwrap((1...6).first { !fallback.getBuddies($0, false).isEmpty })
        XCTAssertEqual(db.getBuddies(buddyTier, false).map { $0.dbfId }, fallback.getBuddies(buddyTier, false).map { $0.dbfId })
    }
}
