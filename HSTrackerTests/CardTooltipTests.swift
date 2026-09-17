//
//  CardTooltipTests.swift
//  HSTrackerTests
//
//  Created by Francisco Moraes on 9/16/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import XCTest
@testable import HSTracker

// Mirrors HDT's CardTooltipViewModelTests: which card the hover tooltip puts in
// its primary slot, and which - if any - it puts in the golden slot beside it.
@available(macOS 10.15, *)
class CardTooltipTests: HSTrackerTests {

    static var database: Database!

    override class func setUp() {
        super.setUp()
        database = Database()
        database.loadDatabase(splashscreen: nil, withLanguages: [.enUS])
    }

    // The hovered element asks for the triple whenever the card is a
    // Battlegrounds one, which is what CardTooltipRequest.showTriple defaults to.
    private func tooltipCards(_ cardId: String) -> (primary: String, golden: String?) {
        CardTooltipPanel.tooltipCards(for: cardId, showTriple: true)
    }

    func testBattlegroundsMinionShowsNormalCardWithTripleAlongside() {
        let cards = tooltipCards("BG19_010")
        XCTAssertEqual(cards.primary, "BG19_010")
        XCTAssertEqual(cards.golden, "BG19_010_G")
    }

    func testOnlyGoldInGuideMinionShowsGoldenCardAndNothingElse() {
        let cards = tooltipCards("BG32_236")
        XCTAssertEqual(cards.primary, "BG32_236_G")
        XCTAssertNil(cards.golden)
    }

    func testConstructedCardHasNoTriple() {
        let cards = tooltipCards("LOE_077")
        XCTAssertEqual(cards.primary, "LOE_077")
        XCTAssertNil(cards.golden)
    }

    // showTriple is what the hovered element declares; a Battlegrounds minion
    // hovered from somewhere that asks for no triple still shows its own card.
    func testShowTripleFalseKeepsTheHoveredCard() {
        let cards = CardTooltipPanel.tooltipCards(for: "BG19_010", showTriple: false)
        XCTAssertEqual(cards.primary, "BG19_010")
        XCTAssertNil(cards.golden)
    }
}
