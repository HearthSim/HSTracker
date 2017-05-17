//
//  NetImportTest.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 28/02/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import XCTest
import RealmSwift
import CleanroomLogger
import Kanna
@testable import HSTracker

@available(OSX 10.10, *)
class NetImportTest: XCTestCase {
    
    let importTimeout: TimeInterval = 60
    var database: Database!

    override func setUp() {	
		// initialize test realm's database
        Realm.Configuration.defaultConfiguration.inMemoryIdentifier = self.name

        database = Database()
        database.loadDatabase(splashscreen: nil, withLanguages: [.enUS])

        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    private func verifyDeck(html: String) {
        guard let doc = Kanna.HTML(html: html, encoding: .utf8) else {
            XCTFail("HTML is not valid")
            return
        }
        let importer = MetaTagImporter()
        guard let (deck, cards) = importer.loadDeck(doc: doc, url: ""),
            cards.isValidDeck() else {
                XCTFail("Deck is not valid")
                return
        }

        RealmHelper.add(deck: deck, with: cards)
        do {
            let realm = try Realm()
            guard let newDeck = realm.objects(Deck.self)
                .filter("name = 'Classic Hunter'").first else {
                    XCTFail("Can not fetch deck")
                    return
            }
            XCTAssertEqual(newDeck.playerClass, .hunter, "Invalid class found")
            XCTAssertEqual(newDeck.countCards(), 30, "Deck should have 30 cards")
            XCTAssertNotNil(newDeck.sortedCards.first({
                $0.id == "CS2_172" && $0.count == 2
            }), "Bloodfen Raptor should be present")

            guard let string = DeckSerializer.serialize(deck: deck) else {
                XCTFail("Can not generate deck string")
                return
            }
            XCTAssertEqual(string, "AAECAR8GxwPJBLsFmQfZB/gIDI0B2AGoArUDhwSSBe0G6wfbCe0JgQr+DAA=", "Generated deck string is not correct")
        } catch {
            XCTFail("Can not fetch deck")
        }
    }

    func testMetatagsWithClassAndCards() {
        let html = "<head>"
            + "<meta property='x-hearthstone:deck' content='Classic Hunter'/>"
            + "<meta property='x-hearthstone:deck:hero' content='HERO_05'/>"
            + "<meta property='x-hearthstone:deck:cards' content='EX1_554,EX1_610,DS1_178,EX1_017,EX1_162,EX1_543,CS2_084,CS2_084,CS2_172,CS2_172,EX1_539,EX1_539,NEW1_031,NEW1_031,EX1_611,EX1_611,EX1_029,EX1_029,DS1_185,DS1_185,DS1_070,DS1_070,EX1_538,EX1_538,EX1_534,EX1_534,EX1_531,EX1_531,EX1_536,EX1_536'/>"
            + "<meta property='x-hearthstone:deck:url' content='https://github.com/HearthSim/Hearthstone-Deck-Tracker/wiki/RFC-Importing-Implementation'/>"
            + "</head>"
        verifyDeck(html: html)
    }

    func testMetatagsWithDeckString() {
        let html = "<head>"
            + "<meta property='x-hearthstone:deck' content='Classic Hunter'/>"
            + "<meta property='x-hearthstone:deck:deckstring' content='AAECAR8GxwPJBLsFmQfZB/gIDI0B2AGoArUDhwSSBe0G6wfbCe0JgQr+DAA='/>"
            + "<meta property='x-hearthstone:deck:url' content='https://github.com/HearthSim/Hearthstone-Deck-Tracker/wiki/RFC-Importing-Implementation'/>"
            + "</head>"
        verifyDeck(html: html)
    }

    func testCompleteImport() {
        let str = "### Classic Hunter\n"
            + "# Class: Hunter\n"
            + "# Format: Standard\n"
            + "# Year of the Mammoth\n"
            + "#\n"
            + "# 2x (1) Arcane Shot\n"
            + "# 2x (1) Hunter's Mark\n"
            + "# 2x (1) Leper Gnome\n"
            + "# 2x (2) Bloodfen Raptor\n"
            + "# 1x (2) Dire Wolf Alpha\n"
            + "# ....\n"
            + "# \n"
            + "AAECAR8GxwPJBLsFmQfZB/gIDI0B2AGoArUDhwSSBe0G6wfbCe0JgQr+DAA=\n"
            + "#\n"
            + "# To use this deck, copy it to your clipboard and create a new deck in Hearthstone\n"

        guard let deck = DeckSerializer.deserialize(input: str) else {
            XCTFail("Can not decode deck")
            return
        }
        XCTAssertEqual(deck.name, "Classic Hunter", "Deck name is not correct")
        XCTAssertEqual(deck.playerClass, .hunter, "Invalid class found")
        XCTAssertTrue(deck.cards.map({ $0.id }).contains("EX1_539"), "Kill Command not found")
    }

    private func verifyDeck(importer: Importer, url: String, name: String, playerClass: CardClass,
                            cardId: String, cardCount: Int, cardName: String) {

        XCTAssert(url.lowercased().match(importer.handleUrl),
                  "\(type(of: importer)) does not handle \(url)")

        let asyncExpectation = expectation(description: "Testing \(url)")
        do {
            try NetImporter.netImport(url: url) { (deck, _) -> Void in
                defer { asyncExpectation.fulfill() }
                guard let _ = deck else {
                    XCTFail("Deck should not be nil")
                    return
                }
                do {
                    let realm = try Realm()
                    guard let newDeck = realm.objects(Deck.self)
                        .filter("name = '\(name)'").first else {
                            XCTFail("Can not fetch deck")
                            return
                    }
                    XCTAssertEqual(newDeck.playerClass, playerClass, "Invalid class found")
                    XCTAssertEqual(newDeck.countCards(), 30, "Deck should have 30 cards")
                    XCTAssertNotNil(newDeck.sortedCards.first({
                        $0.id == cardId && $0.count == cardCount
                    }), "\(cardName) should be present")
                } catch {
                    XCTFail("Can not fetch deck")
                }
            }

            self.waitForExpectations(timeout: importTimeout) { error in
                XCTAssertNil(error, "Connection timed out after \(self.importTimeout) seconds")
            }
        } catch {
            XCTFail("Deck should not be nil")
        }
    }

    func testHearthArena() {
        let url = "http://www.heartharena.com/arena-run/260979"
        let deckName = String(format: NSLocalizedString("Arena Warrior %@", comment: ""),
                              HearthArena.dateFormatter.string(from: Date()) )
        verifyDeck(importer: HearthArena(),
                   url: url, name: deckName, playerClass: .warrior,
                   cardId: "EX1_597", cardCount: 2, cardName: "Imp Master")
    }

    func testHearthNews() {
        let url = "http://www.hearthnews.fr/decks/7070"
        verifyDeck(importer: MetaTagImporter(),
                   url: url, name: "Réno NeFaitRien (Néfarian)", playerClass: .priest,
                   cardId: "FP1_001", cardCount: 1, cardName: "Zombie Chow")
    }

    func testHearthstoneDecks() {
        let url = "http://www.hearthstone-decks.com/deck/voir/reno-reincarnation-7844"
        verifyDeck(importer: HearthstoneDecks(),
                   url: url, name: "Reno/Réincarnation", playerClass: .shaman,
                   cardId: "AT_052", cardCount: 1, cardName: "Totem Golem")
    }

    func testHearthpwn() {
        let url = "http://www.hearthpwn.com/decks/432773-ostkakas-standard-miracle-rogue"
        verifyDeck(importer: Hearthpwn(),
                   url: url, name: "Standard Miracle Rogue", playerClass: .rogue,
                   cardId: "CS2_072", cardCount: 2, cardName: "Backstab")
    }

    func testHearthpwnDecks() {
        let url = "http://www.hearthpwn.com/deckbuilder/warrior#50:2;73:1;96:1;215:2;227:2;297:2;493:2;632:1;644:1;7734:2;7749:2;12215:2;14448:1;14464:2;22264:1;22276:1;22309:2;27210:1;27211:2"
        verifyDeck(importer: HearthpwnDeckBuilder(),
                   url: url, name: "Warrior Deck", playerClass: .warrior,
                   cardId: "BRM_015", cardCount: 2, cardName: "Revenge")
    }

    func testHearthStats() {
        let url = "http://hearthstats.net/decks/mech-mage--36939/public_show?locale=en"
        verifyDeck(importer: Hearthstats(),
                   url: url, name: "Mech Mage", playerClass: .mage,
                   cardId: "GVG_006", cardCount: 2, cardName: "Mechwarper")
    }

    func testHearthHead() {
        let url = "http://www.hearthhead.com/decks/fun-easy-win-dragon-warrior"
        verifyDeck(importer: MetaTagImporter(),
                   url: url, name: "Fun Easy Win Dragon Warrior", playerClass: .warrior,
                   cardId: "EX1_414", cardCount: 1, cardName: "Grommash Hellscream")
    }

    func testHearthstoneTopDecks() {
        let url = "https://www.hearthstonetopdecks.com/decks/rostys-totem-shaman-october-2016-season-31/"
        verifyDeck(importer: HearthstoneTopDecks(),
                   url: url, name: "Rosty’s Totem Shaman (October 2016, Season 31)",
                   playerClass: .shaman,
                   cardId: "EX1_246", cardCount: 2, cardName: "Hex")
    }

    func testHearthstoneTopDeck() {
        let url = "http://www.hearthstonetopdeck.com/deck/standard/6133/yogg-druid-pavel"
        verifyDeck(importer: HearthstoneTopDeck(),
                   url: url, name: "#1 - Yogg Druid - Pavel", playerClass: .druid,
                   cardId: "OG_134", cardCount: 1, cardName: "Yogg-Saron, Hope's End")
    }

    func testTempostorm() {
        let url = "https://tempostorm.com/hearthstone/decks/burgle-reno-bounce-rogue"
        verifyDeck(importer: Tempostorm(),
                   url: url, name: "Burgle Reno Bounce Rogue", playerClass: .rogue,
                   cardId: "AT_031", cardCount: 1, cardName: "Cutpurse")
    }

    func testHearthstoneHeroes() {
        Cards.cards.removeAll()
        database.loadDatabase(splashscreen: nil, withLanguages: [.deDE, .enUS])
        let url = "http://www.hearthstoneheroes.de/decks/hells-hexenmeister/"
        verifyDeck(importer: HearthstoneHeroes(),
                   url: url,
                   name: "Hell’s [Legendary] Hexenmeister – Tourney-winning ladder-shredding warlock",
                   playerClass: .warlock,
                   cardId: "EX1_319", cardCount: 2, cardName: "Flame Imp")
    }
}
