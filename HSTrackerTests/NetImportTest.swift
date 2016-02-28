//
//  NetImportTest.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 28/02/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import XCTest

@testable import HSTracker

class NetImportTest: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testHearthArena() {
        let url = "http://www.heartharena.com/arena-run/260979"
        self.measureBlock {
            do {
                try NetImporter.netImport(url, { (deck) -> Void in
                    XCTAssertNotNil(deck, "deck should be imported")
                })
            } catch {
                XCTFail("Deck should be imported")
            }
        }
    }

    func testExample() {
        //let heartharena =
        //let hearthnews = "http://www.hearthnews.fr/decks/7070"
        //let hearthstoneDecks = "http://www.hearthstone-decks.com/deck/voir/reno-reincarnation-7844"
        //let hearthpwn = "http://www.hearthpwn.com/decks/432773-ostkakas-standard-miracle-rogue"
        //let hearthpwnDeckbuilder = "http://www.hearthpwn.com/deckbuilder/warrior#50:2;73:1;96:1;215:2;227:2;297:2;493:2;632:1;644:1;7734:2;7749:2;12215:2;14448:1;14464:2;22264:1;22276:1;22309:2;27210:1;27211:2"
        //let hearthstats = "http://hearthstats.net/decks/mage-meca--1049/public_show?locale=en"
        //let hearthhead = "http://www.hearthhead.com/deck=158864/fun-easy-win-dragon-warrior"
        
        /*let url = hearthhead
        do {
        try NetImporter.netImport(url, { (deck) -> Void in
        DDLogVerbose("\(deck)")
        })
        } catch {
        DDLogVerbose("error")
        }*/

    }

}
