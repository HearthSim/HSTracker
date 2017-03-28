//
//  NetImportTest.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 28/02/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import XCTest
import RealmSwift
@testable import HSTracker

@available(OSX 10.11, *)
class NetImportTest: XCTestCase {
    
    let importTimeout: TimeInterval = 60

    override func setUp() {
		Paths.initDirs()
		
		// initialize test realm's database
        Realm.Configuration.defaultConfiguration.inMemoryIdentifier = self.name
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testHearthArena() {
        
        let asyncExpectation = expectation(description: "hearthArenaDeckImportAsynchTest")
        let url = "http://www.heartharena.com/arena-run/260979"
        do {
            try NetImporter.netImport(url: url, completion: { (deck) -> Void in
                XCTAssertNotNil(deck, "Deck should not be nil")
                asyncExpectation.fulfill()
            })
                
            self.waitForExpectations(timeout: importTimeout) { error in
                XCTAssertNil(error, "Connection timed out after \(self.importTimeout) seconds")
            }
        } catch {
            XCTFail("Deck should not be nil")
        }
    }

    func testHearthNews() {
        
        let asyncExpectation = expectation(description: "hearthNewsDeckImportAsynchTest")
        let url = "http://www.hearthnews.fr/decks/7070"

        do {
            try NetImporter.netImport(url: url, completion: { (deck) -> Void in
                XCTAssertNotNil(deck, "Deck should not be nil")
                asyncExpectation.fulfill()
            })
                
            self.waitForExpectations(timeout: importTimeout) { error in
                XCTAssertNil(error, "Connection timed out after \(self.importTimeout) seconds")
            }
        } catch {
            XCTFail("Deck should not be nil")
        }

    }

    func testHearthstoneDecks() {
        
        let asyncExpectation = expectation(description: "hearthstoneDecksDeckImportAsynchTest")
        let url = "http://www.hearthstone-decks.com/deck/voir/reno-reincarnation-7844"
        do {
            try NetImporter.netImport(url: url, completion: { (deck) -> Void in
                XCTAssertNotNil(deck, "Deck should not be nil")
                asyncExpectation.fulfill()
            })
            
            self.waitForExpectations(timeout: importTimeout) { error in
                XCTAssertNil(error, "Connection timed out after \(self.importTimeout) seconds")
            }
        } catch {
            XCTFail("Deck should not be nil")
        }
    }

    func testHearthpwn() {
        
        let asyncExpectation = expectation(description: "hearthpwnDeckImportAsynchTest")
        let url = "http://www.hearthpwn.com/decks/432773-ostkakas-standard-miracle-rogue"
        do {
            try NetImporter.netImport(url: url, completion: { (deck) -> Void in
                XCTAssertNotNil(deck, "Deck should not be nil")
                asyncExpectation.fulfill()
            })
            
            self.waitForExpectations(timeout: importTimeout) { error in
                XCTAssertNil(error, "Connection timed out after \(self.importTimeout) seconds")
            }
        } catch {
            XCTFail("Deck should not be nil")
        }
    }

    func testHearthpwnDecks() {
        
        let asyncExpectation = expectation(description: "hearthpwnDecksDeckImportAsynchTest")
        let url = "http://www.hearthpwn.com/deckbuilder/warrior#50:2;73:1;96:1;215:2;227:2;297:2;493:2;632:1;644:1;7734:2;7749:2;12215:2;14448:1;14464:2;22264:1;22276:1;22309:2;27210:1;27211:2"
        do {
            try NetImporter.netImport(url: url, completion: { (deck) -> Void in
                XCTAssertNotNil(deck, "Deck should not be nil")
                asyncExpectation.fulfill()
            })
            
            self.waitForExpectations(timeout: importTimeout) { error in
                XCTAssertNil(error, "Connection timed out after \(self.importTimeout) seconds")
            }
        } catch {
            XCTFail("Deck should not be nil")
        }
    }

    func testHearthStats() {
        
        let asyncExpectation = expectation(description: "hearthStatsDeckImportAsynchTest")
        let url = "http://hearthstats.net/decks/mech-mage--36939/public_show?locale=en"
        do {
            try NetImporter.netImport(url: url, completion: { (deck) -> Void in
                XCTAssertNotNil(deck, "Deck should not be nil")
                asyncExpectation.fulfill()
            })
            
            self.waitForExpectations(timeout: importTimeout) { error in
                XCTAssertNil(error, "Connection timed out after \(self.importTimeout) seconds")
            }
        } catch {
            XCTFail("Deck should not be nil")
        }
    }

    func testHearthHead() {
        
        let asyncExpectation = expectation(description: "hearthHeadDeckImportAsynchTest")
        let url = "http://www.hearthhead.com/decks/fun-easy-win-dragon-warrior"
        do {
            try NetImporter.netImport(url: url, completion: { (deck) -> Void in
                XCTAssertNotNil(deck, "Deck should not be nil")
                asyncExpectation.fulfill()
            })
            
            self.waitForExpectations(timeout: importTimeout) { error in
                XCTAssertNil(error, "Connection timed out after \(self.importTimeout) seconds")
            }
        } catch {
            XCTFail("Deck should not be nil")
        }
    }

    func testHearthstoneTopDecks() {
        let asyncExpectation = expectation(description: "hearthstoneTopDecksImportAsynchTest")
        let url = "https://www.hearthstonetopdecks.com/decks/rostys-totem-shaman-october-2016-season-31/"
        do {
            try NetImporter.netImport(url: url, completion: { (deck) -> Void in
                XCTAssertNotNil(deck, "Deck should not be nil")
                asyncExpectation.fulfill()
            })

            self.waitForExpectations(timeout: importTimeout) { error in
                XCTAssertNil(error, "Connection timed out after \(self.importTimeout) seconds")
            }
        } catch {
            XCTFail("Deck should not be nil")
        }
    }

    func testHearthstoneTopDeck() {
        let asyncExpectation = expectation(description: "hearthstoneTopDeckImportAsynchTest")
        let url = "http://www.hearthstonetopdeck.com/deck/standard/6133/yogg-druid-pavel"
        do {
            try NetImporter.netImport(url: url, completion: { (deck) -> Void in
                XCTAssertNotNil(deck, "Deck should not be nil")
                asyncExpectation.fulfill()
            })

            self.waitForExpectations(timeout: importTimeout) { error in
                XCTAssertNil(error, "Connection timed out after \(self.importTimeout) seconds")
            }
        } catch {
            XCTFail("Deck should not be nil")
        }
    }

    func testTempostorm() {
        let asyncExpectation = expectation(description: "tempostormImportAsynchTest")
        let url = "https://www.hearthstonetopdecks.com/decks/rostys-totem-shaman-october-2016-season-31/"
        do {
            try NetImporter.netImport(url: url, completion: { (deck) -> Void in
                XCTAssertNotNil(deck, "Deck should not be nil")
                asyncExpectation.fulfill()
            })

            self.waitForExpectations(timeout: importTimeout) { error in
                XCTAssertNil(error, "Connection timed out after \(self.importTimeout) seconds")
            }
        } catch {
            XCTFail("Deck should not be nil")
        }
    }

    func testHearthstoneHeroes() {
        let asyncExpectation = expectation(description: "hearthstoneHeroesImportAsynchTest")
        let url = "http://www.hearthstoneheroes.de/decks/hells-hexenmeister/"
        do {
            try NetImporter.netImport(url: url, completion: { (deck) -> Void in
                XCTAssertNotNil(deck, "Deck should not be nil")
                asyncExpectation.fulfill()
            })

            self.waitForExpectations(timeout: importTimeout) { error in
                XCTAssertNil(error, "Connection timed out after \(self.importTimeout) seconds")
            }
        } catch {
            XCTFail("Deck should not be nil")
        }
    }
}
