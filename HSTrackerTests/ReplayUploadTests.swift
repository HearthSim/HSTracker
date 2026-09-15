//
//  ReplayUploadTests.swift
//  HSTracker
//
//  Created by Istvan Fehervari on 09/05/2017.
//  Copyright © 2017 Benjamin Michotte. All rights reserved.
//

import XCTest

@testable import HSTracker

class ReplayUploadTests: HSTrackerTests {

	override func setUp() {
		super.setUp()
	}

	override func tearDown() {
		super.tearDown()
	}

	/// The upload metadata goes to HSReplay as JSON, so the property names are
	/// part of the wire format rather than an internal detail.
	func testMetadataEncoding() throws {
		let player = UploadMetaData.Player()

		player.stars = 1
		player.wins = 20
		player.losses = 10
		player.deck = ["one", "two"]
		player.deck_id = 12345
		player.cardback = 3

		let data = try JSONEncoder().encode(player)
		let json = try XCTUnwrap(try JSONSerialization.jsonObject(with: data) as? [String: Any])

		XCTAssertEqual(json["stars"] as? Int, player.stars)
		XCTAssertEqual(json["wins"] as? Int, player.wins)
		XCTAssertEqual(json["losses"] as? Int, player.losses)
		XCTAssertEqual(json["deck"] as? [String], player.deck)
		XCTAssertEqual(json["deck_id"] as? Int64, player.deck_id)
		XCTAssertEqual(json["cardback"] as? Int, player.cardback)

		// Unset fields are omitted rather than sent as null.
		XCTAssertNil(json["rank"])
		XCTAssertNil(json["legend_rank"])
	}
}
