//
//  ReplayUploadTests.swift
//  HSTracker
//
//  Created by Istvan Fehervari on 09/05/2017.
//  Copyright © 2017 Benjamin Michotte. All rights reserved.
//

import XCTest
import Wrap

@testable import HSTracker

class ReplayUploadTests: XCTestCase {
	
	override func setUp() {
		super.setUp()
	}
	
	override func tearDown() {
		super.tearDown()
	}
	
	func testMetadataWrap() {
		let player = UploadMetaData.Player()
		
		player.rank = 1
		player.legendRank = 0
		player.stars = 1
		player.wins = 20
		player.losses = 10
		player.deck = ["one", "two"]
		player.deckId = 12345
		player.cardBack = 3
		
		guard let wrappedPlayer: [String : Any] = try? wrap(player) else {
			XCTFail()
			return
		}
		
		XCTAssert(wrappedPlayer["rank"] as! Int == player.rank!)
		XCTAssert(wrappedPlayer["cardback"] as! Int == player.cardBack!)
		XCTAssert(wrappedPlayer["deck"] as! [String] == player.deck!)
	}
}

