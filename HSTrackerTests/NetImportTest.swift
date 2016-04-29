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
    var expectation: XCTestExpectation?
    var notification: NSObjectProtocol?

    override func setUp() {
        super.setUp()    }

    override func tearDown() {
        super.tearDown()
    }

    func testHearthArena() {
        print("Waiting 10 seconds for Database to be started")
        expectationForNotification("hstracker_is_ready", object: nil, handler: nil)
        waitForExpectationsWithTimeout(10, handler: nil)

        let url = "http://www.heartharena.com/arena-run/260979"
        self.measureBlock {
            do {
                try NetImporter.netImport(url, { (deck) -> Void in
                    XCTAssertNotNil(deck, "Deck should not be nil")
                })
            } catch {
                XCTFail("Deck should not be nil")
            }
        }
    }

    func testHearthNews() {
        let url = "http://www.hearthnews.fr/decks/7070"
        self.measureBlock {
            do {
                try NetImporter.netImport(url, { (deck) -> Void in
                    XCTAssertNotNil(deck, "Deck should not be nil")
                })
            } catch {
                XCTFail("Deck should not be nil")
            }
        }
    }

    func testHearthstoneDecks() {
        let url = "http://www.hearthstone-decks.com/deck/voir/reno-reincarnation-7844"
        self.measureBlock {
            do {
                try NetImporter.netImport(url, { (deck) -> Void in
                    XCTAssertNotNil(deck, "Deck should not be nil")
                })
            } catch {
                XCTFail("Deck should not be nil")
            }
        }
    }

    func testHearthpwn() {
        let url = "http://www.hearthpwn.com/decks/432773-ostkakas-standard-miracle-rogue"
        self.measureBlock {
            do {
                try NetImporter.netImport(url, { (deck) -> Void in
                    XCTAssertNotNil(deck, "Deck should not be nil")
                })
            } catch {
                XCTFail("Deck should not be nil")
            }
        }
    }

    func testHearthpwnDecks() {
        let url = "http://www.hearthpwn.com/deckbuilder/warrior#50:2;73:1;96:1;215:2;227:2;297:2;493:2;632:1;644:1;7734:2;7749:2;12215:2;14448:1;14464:2;22264:1;22276:1;22309:2;27210:1;27211:2"
        self.measureBlock {
            do {
                try NetImporter.netImport(url, { (deck) -> Void in
                    XCTAssertNotNil(deck, "Deck should not be nil")
                })
            } catch {
                XCTFail("Deck should not be nil")
            }
        }
    }

    func testHearthStats() {
        let url = "http://hearthstats.net/decks/mage-meca--1049/public_show?locale=en"
        self.measureBlock {
            do {
                try NetImporter.netImport(url, { (deck) -> Void in
                    XCTAssertNotNil(deck, "Deck should not be nil")
                })
            } catch {
                XCTFail("Deck should not be nil")
            }
        }
    }

    func testHearthHead() {
        let url = "http://www.hearthhead.com/deck=158864/fun-easy-win-dragon-warrior"
        self.measureBlock {
            do {
                try NetImporter.netImport(url, { (deck) -> Void in
                    XCTAssertNotNil(deck, "Deck should not be nil")
                })
            } catch {
                XCTFail("Deck should not be nil")
            }
        }
    }
}
