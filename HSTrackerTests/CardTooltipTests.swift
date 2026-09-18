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

    // MARK: - Placement

    // A 1920x1080 overlay window, and a deck-tracker row against each of its
    // vertical edges - which is where both trackers actually sit.
    private let overlay = NSRect(x: 0, y: 0, width: 1920, height: 1080)
    private func row(atX x: CGFloat) -> NSRect {
        NSRect(x: x, y: 500, width: 200, height: 34)
    }

    private func placement(of row: NSRect) -> CardTooltipPlacement {
        CardTooltipPanel.placedFrame(panelWidth: 220, preferred: .right,
                                     anchor: row, bounds: overlay,
                                     horizontalOffset: 0, verticalOffset: 0).placement
    }

    // CardTile.xaml asks for Placement="Right" and SetTooltip keeps it while the
    // right side has room, which is the opponent tracker's case.
    func testRowOnTheLeftEdgeKeepsTheRenderOnItsRight() {
        XCTAssertEqual(placement(of: row(atX: 0)), .right)
    }

    // "Correct placement if tooltip would go outside of window, and it fit on the
    // other side" - the player tracker, hard against the right edge.
    func testRowOnTheRightEdgeFlipsTheRenderToItsLeft() {
        XCTAssertEqual(placement(of: row(atX: 1720)), .left)
    }

    // The render is centred on the row, not hung off its top edge, and is clamped
    // inside the overlay window rather than the screen.
    func testRenderIsCentredOnTheRowAndClampedToTheOverlay() {
        let anchor = row(atX: 0)
        let frame = CardTooltipPanel.placedFrame(panelWidth: 220, preferred: .right,
                                                 anchor: anchor, bounds: overlay,
                                                 horizontalOffset: 0, verticalOffset: 0).frame
        XCTAssertEqual(frame.minX, anchor.maxX)
        XCTAssertEqual(frame.midY, anchor.midY, accuracy: 0.001)

        let high = CardTooltipPanel.placedFrame(panelWidth: 220, preferred: .right,
                                                anchor: row(atX: 0).offsetBy(dx: 0, dy: 520),
                                                bounds: overlay,
                                                horizontalOffset: 0, verticalOffset: 0).frame
        XCTAssertEqual(high.maxY, overlay.maxY)
    }

    // The related-cards grid is butted against the render, so the deck lists have
    // to know how wide it ended up: a Battlegrounds minion's golden companion
    // doubles it, and the grid would otherwise land on top of the golden card.
    func testProjectedFrameReservesTheGoldenCompanionsWidth() {
        let anchor = row(atX: 0)
        let constructed = CardTooltipPanel.projectedFrame(
            for: CardTooltipRequest(cardId: "LOE_077", showTriple: false),
            anchor: anchor, bounds: overlay)
        let battlegrounds = CardTooltipPanel.projectedFrame(
            for: CardTooltipRequest(cardId: "BG19_010", showTriple: true),
            anchor: anchor, bounds: overlay)
        XCTAssertEqual(battlegrounds.width, constructed.width * 2)
        XCTAssertEqual(constructed.minX, anchor.maxX)
        XCTAssertEqual(battlegrounds.minX, anchor.maxX)
    }

    // MARK: - Which hover owns the panel

    // The panel is a singleton every hovered element shares, and a show waits out a delay the
    // cursor routinely beats, so these cover which hover it belongs to while one card is still
    // rendered and another has already been asked for.
    //
    // Driven the way the overlay's own elements drive it - a registered CardHoverNSView and the
    // `.registry` source - rather than through `.trackingArea`: the app hosting these tests keeps
    // running its own window bookkeeping, and WindowManager.hideGameTrackers takes every
    // `.trackingArea` tooltip down with it whenever it happens to fire mid-test.

    // Held for the length of a test: the registry keeps weak references, and the show delay's
    // liveness guard reads the view back out of it.
    private var hoverViews: [CardHoverNSView] = []
    private var hoverWindow: NSWindow?

    private func hover(_ cardId: String) {
        let window = hoverWindow ?? NSWindow(contentRect: NSRect(x: 0, y: 0, width: 100, height: 100),
                                             styleMask: [.borderless], backing: .buffered, defer: true)
        hoverWindow = window
        let request = CardTooltipRequest(cardId: cardId, showTriple: false)
        let view = CardHoverNSView(frame: NSRect(x: 0, y: 0, width: 50, height: 20))
        window.contentView?.addSubview(view)
        view.update(tooltip: .card(request))
        hoverViews.append(view)
        CardTooltipPanel.shared.show(request, anchor: row(atX: 0), bounds: overlay)
    }

    private func settle(_ seconds: TimeInterval) {
        let waited = expectation(description: "settled")
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) { waited.fulfill() }
        wait(for: [waited], timeout: seconds + 2)
    }

    // The panel is a singleton, so each of these starts and ends by putting it back to nothing
    // hovered - otherwise one test's leftover pending show or hide decides the next one.
    override func setUp() {
        super.setUp()
        CardTooltipPanel.shared.hide()
    }

    override func tearDown() {
        CardTooltipPanel.shared.hide()
        hoverViews.forEach { $0.removeFromSuperview() }
        hoverViews = []
        hoverWindow = nil
        super.tearDown()
    }

    // The cursor crossing a second row on its way off the list: the second row's hover ends while
    // its own show is still pending, so the first card is what is still on screen - and it is the
    // second row's hover, the one that owns the panel, that has to take it down. Nothing asks
    // again afterwards, so a tooltip left up here stays up for the rest of the game.
    func testLeavingARowDismissesTheCardStillShownForThePreviousOne() {
        hover("LOE_077")
        settle(0.4)
        XCTAssertEqual(CardTooltipPanel.shared.currentCardId, "LOE_077")

        hover("BG19_010")
        CardTooltipPanel.shared.hide(ifShowing: "BG19_010")
        settle(0.5)

        XCTAssertNil(CardTooltipPanel.shared.currentCardId)
        XCTAssertFalse(CardTooltipPanel.shared.isVisible)
    }

    // The other order: an element the cursor has already left reports so after a newer hover has
    // claimed the panel. That hide belongs to nobody, and has to leave the newer hover's pending
    // show alone - the cursor sweeps that drive these only act on changes, so a show cancelled
    // here is never asked for again.
    func testAStaleHideLeavesTheNewerHoversTooltipAlone() {
        hover("LOE_077")
        settle(0.4)

        hover("BG19_010")
        CardTooltipPanel.shared.hide(ifShowing: "LOE_077")
        settle(0.5)

        XCTAssertEqual(CardTooltipPanel.shared.currentCardId, "BG19_010")
    }
}
