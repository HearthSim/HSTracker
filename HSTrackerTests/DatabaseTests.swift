//
//  DatabaseTests.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 25/03/17.
//  Copyright © 2017 Benjamin Michotte. All rights reserved.
//

import XCTest
@testable import HSTracker

class DatabaseTests: XCTestCase {

    var database: Database!

    override func setUp() {
        super.setUp()
        database = Database()
        database.loadDatabase(splashscreen: nil, withLanguages: [.enUS])
    }

    override func tearDown() {
        super.tearDown()
    }

    func testFromId() {
        guard let card = Cards.any(byId: "AT_063t") else {
            XCTFail("Dreadscale is nil")
            return
        }

        XCTAssertEqual(card.name, "Dreadscale", "Dreadscale name")
        XCTAssertEqual(card.artist, "Zoltan Boros", "Dreadscale artist")
        XCTAssertEqual(card.attack, 4, "Dreadscale attack")
        XCTAssert(card.collectible, "Dreadscale collectible")
        XCTAssertEqual(card.cost, 3, "Dreadscale cost")
        XCTAssertEqual(card.health, 2, "Dreadscale health")
        XCTAssertEqual(card.playerClass, CardClass.hunter, "Dreadscale playerClass")
        XCTAssertEqual(card.race, Race.beast, "Dreadscale race")
        XCTAssertEqual(card.rarity, Rarity.legendary, "Dreadscale rarity")
        XCTAssertEqual(card.set, CardSet.tgt, "Dreadscale set")
        XCTAssertEqual(card.text, "At the end of your turn, deal 1 damage to all other minions.", "Dreadscale text")
        XCTAssertEqual(card.type, CardType.minion, "Dreadscale type")
    }

    func testGetFromName() {
        guard let card = Cards.by(englishName: "Baron Geddon") else {
            XCTFail("Baron Geddon is nil")
            return
        }

        XCTAssertEqual(card.id, "EX1_249", "Baron Geddon")
        XCTAssertEqual(card.artist, "Ian Ameling", "Baron Geddon artist")
        XCTAssertEqual(card.attack, 7, "Baron Geddon attack")
        XCTAssert(card.collectible, "Baron Geddon collectible")
        XCTAssertEqual(card.cost, 7, "Baron Geddon cost")
        XCTAssertEqual(card.health, 5, "Baron Geddon health")
        XCTAssertEqual(card.playerClass, CardClass.neutral, "Baron Geddon playerClass")
        XCTAssertEqual(card.race, Race.elemental, "Baron Geddon race")
        XCTAssertEqual(card.rarity, Rarity.legendary, "Baron Geddon rarity")
        XCTAssertEqual(card.set, CardSet.expert1, "Baron Geddon set")
        XCTAssertEqual(card.text, "At the end of your turn, deal 2 damage to ALL other characters.",  "Baron Geddon text")
        XCTAssertEqual(card.type, CardType.minion, "Baron Geddon type")
    }

    func testGetFromNameUncollectible() {
        guard let card = Cards.cards.filter({
            return $0.enName == "Baron Geddon" && !$0.collectible
        }).first else {
            XCTFail("Uncollectible Baron Geddon is nil")
            return
        }

        XCTAssert(card.id.contains("BRMA05"), "Uncollectible Baron Geddon")
        XCTAssertEqual(card.set, CardSet.brm, "Uncollectible Baron Geddon set")
        XCTAssertEqual(card.type, CardType.hero, "Uncollectible Baron Geddon hero")
    }

    func testHeroSkins() {
        guard let alleria = Cards.hero(byId: "HERO_05a") else {
            XCTFail("Alleria is nil")
            return
        }

        XCTAssertEqual(alleria.playerClass, CardClass.hunter, "Alleria")
        XCTAssertEqual(alleria.set, CardSet.hero_skins, "Alleria set")
        XCTAssertEqual(alleria.type, CardType.hero, "Alleria type")

        guard let alleriaPower = Cards.any(byId: "DS1h_292_H1") else {
            XCTFail("Alleria is nil")
            return
        }

        XCTAssertEqual(alleriaPower.name, "Steady Shot", "Alleria power")
        XCTAssertEqual(alleriaPower.type, CardType.hero_power, "Alleria power")
        XCTAssertEqual(alleriaPower.playerClass, CardClass.hunter, "Alleria power playerClass")
    }
}
