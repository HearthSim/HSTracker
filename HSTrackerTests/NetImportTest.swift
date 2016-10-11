//
//  NetImportTest.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 28/02/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import XCTest

@testable import HSTracker

@available(OSX 10.11, *)
class NetImportTest: XCTestCase {

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testHearthArena() {
        
        let asyncExpectation = expectationWithDescription("hearthArenaDeckImportAsynchTest")
        let url = "http://www.heartharena.com/arena-run/260979"
        do {
            try NetImporter.netImport(url, completion: { (deck) -> Void in
                XCTAssertNotNil(deck, "Deck should not be nil")
                asyncExpectation.fulfill()
            })
                
            self.waitForExpectationsWithTimeout(10) { error in
                XCTAssertNil(error, "Something went horribly wrong")
            }
        } catch {
            XCTFail("Deck should not be nil")
        }
    }

    func testHearthNews() {
        
        let asyncExpectation = expectationWithDescription("hearthNewsDeckImportAsynchTest")
        let url = "http://www.hearthnews.fr/decks/7070"

        do {
            try NetImporter.netImport(url, completion: { (deck) -> Void in
                XCTAssertNotNil(deck, "Deck should not be nil")
                asyncExpectation.fulfill()
            })
                
            self.waitForExpectationsWithTimeout(10) { error in
                XCTAssertNil(error, "Something went horribly wrong")
            }
        } catch {
            XCTFail("Deck should not be nil")
        }

    }

    func testHearthstoneDecks() {
        
        let asyncExpectation = expectationWithDescription("hearthstoneDecksDeckImportAsynchTest")
        let url = "http://www.hearthstone-decks.com/deck/voir/reno-reincarnation-7844"
        do {
            try NetImporter.netImport(url, completion: { (deck) -> Void in
                XCTAssertNotNil(deck, "Deck should not be nil")
                asyncExpectation.fulfill()
            })
            
            self.waitForExpectationsWithTimeout(10) { error in
                XCTAssertNil(error, "Something went horribly wrong")
            }
        } catch {
            XCTFail("Deck should not be nil")
        }
    }

    func testHearthpwn() {
        
        let asyncExpectation = expectationWithDescription("hearthpwnDeckImportAsynchTest")
        let url = "http://www.hearthpwn.com/decks/432773-ostkakas-standard-miracle-rogue"
        do {
            try NetImporter.netImport(url, completion: { (deck) -> Void in
                XCTAssertNotNil(deck, "Deck should not be nil")
                asyncExpectation.fulfill()
            })
            
            self.waitForExpectationsWithTimeout(10) { error in
                XCTAssertNil(error, "Something went horribly wrong")
            }
        } catch {
            XCTFail("Deck should not be nil")
        }
    }

    func testHearthpwnDecks() {
        
        let asyncExpectation = expectationWithDescription("hearthpwnDecksDeckImportAsynchTest")
        let url = "http://www.hearthpwn.com/deckbuilder/warrior#50:2;73:1;96:1;215:2;227:2;297:2;493:2;632:1;644:1;7734:2;7749:2;12215:2;14448:1;14464:2;22264:1;22276:1;22309:2;27210:1;27211:2"
        do {
            try NetImporter.netImport(url, completion: { (deck) -> Void in
                XCTAssertNotNil(deck, "Deck should not be nil")
                asyncExpectation.fulfill()
            })
            
            self.waitForExpectationsWithTimeout(10) { error in
                XCTAssertNil(error, "Something went horribly wrong")
            }
        } catch {
            XCTFail("Deck should not be nil")
        }
    }

    func testHearthStats() {
        
        let asyncExpectation = expectationWithDescription("hearthStatsDeckImportAsynchTest")
        let url = "http://hearthstats.net/decks/mech-mage--36939/public_show?locale=en"
        do {
            try NetImporter.netImport(url, completion: { (deck) -> Void in
                XCTAssertNotNil(deck, "Deck should not be nil")
                asyncExpectation.fulfill()
            })
            
            self.waitForExpectationsWithTimeout(10) { error in
                XCTAssertNil(error, "Something went horribly wrong")
            }
        } catch {
            XCTFail("Deck should not be nil")
        }
    }

    func testHearthHead() {
        
        let asyncExpectation = expectationWithDescription("hearthHeadDeckImportAsynchTest")
        let url = "http://www.hearthhead.com/deck=158864/fun-easy-win-dragon-warrior"
        do {
            try NetImporter.netImport(url, completion: { (deck) -> Void in
                XCTAssertNotNil(deck, "Deck should not be nil")
                asyncExpectation.fulfill()
            })
            
            self.waitForExpectationsWithTimeout(10) { error in
                XCTAssertNil(error, "Something went horribly wrong")
            }
        } catch {
            XCTFail("Deck should not be nil")
        }
    }

    func testHearthstoneTopDecks() {
        let asyncExpectation = expectationWithDescription("hearthstoneTopDecksImportAsynchTest")
        let url = "https://www.hearthstonetopdecks.com/decks/rostys-totem-shaman-october-2016-season-31/"
        do {
            try NetImporter.netImport(url, completion: { (deck) -> Void in
                XCTAssertNotNil(deck, "Deck should not be nil")
                asyncExpectation.fulfill()
            })

            self.waitForExpectationsWithTimeout(10) { error in
                XCTAssertNil(error, "Something went horribly wrong")
            }
        } catch {
            XCTFail("Deck should not be nil")
        }
    }

    func testHearthstoneTopDeck() {
        let asyncExpectation = expectationWithDescription("hearthstoneTopDeckImportAsynchTest")
        let url = "http://www.hearthstonetopdeck.com/deck/standard/6133/yogg-druid-pavel"
        do {
            try NetImporter.netImport(url, completion: { (deck) -> Void in
                XCTAssertNotNil(deck, "Deck should not be nil")
                asyncExpectation.fulfill()
            })

            self.waitForExpectationsWithTimeout(10) { error in
                XCTAssertNil(error, "Something went horribly wrong")
            }
        } catch {
            XCTFail("Deck should not be nil")
        }
    }

    func testTempostorm() {
        let asyncExpectation = expectationWithDescription("tempostormImportAsynchTest")
        let url = "https://www.hearthstonetopdecks.com/decks/rostys-totem-shaman-october-2016-season-31/"
        do {
            try NetImporter.netImport(url, completion: { (deck) -> Void in
                XCTAssertNotNil(deck, "Deck should not be nil")
                asyncExpectation.fulfill()
            })

            self.waitForExpectationsWithTimeout(10) { error in
                XCTAssertNil(error, "Something went horribly wrong")
            }
        } catch {
            XCTFail("Deck should not be nil")
        }
    }

    func testHearthstoneHeroes() {
        let asyncExpectation = expectationWithDescription("hearthstoneHeroesImportAsynchTest")
        let url = "http://www.hearthstoneheroes.de/decks/hells-hexenmeister/"
        do {
            try NetImporter.netImport(url, completion: { (deck) -> Void in
                XCTAssertNotNil(deck, "Deck should not be nil")
                asyncExpectation.fulfill()
            })

            self.waitForExpectationsWithTimeout(20) { error in
                XCTAssertNil(error, "Something went horribly wrong")
            }
        } catch {
            XCTFail("Deck should not be nil")
        }
    }
}
