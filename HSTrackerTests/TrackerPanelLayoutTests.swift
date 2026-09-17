//
//  TrackerPanelLayoutTests.swift
//  HSTrackerTests
//
//  Created by Francisco Moraes on 9/17/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import SwiftUI
import XCTest
@testable import HSTracker

/// The part of the deck-tracker port that is pure arithmetic: which sections a
/// stack shows, in what order, and how far the card rows have to shrink to fit
/// the box HDT's `PlayerStackHeight` gives them.
@available(macOS 10.15, *)
class TrackerPanelLayoutTests: HSTrackerTests {

    private var saved: [String: Any?] = [:]

    private static let keys = [
        Settings.deck_panel_order_player, Settings.deck_panel_order_opponent,
        Settings.player_deck_height, Settings.opponent_deck_height,
        Settings.overlay_player_scaling, Settings.overlay_opponent_scaling,
        Settings.card_size,
        Settings.show_deck_name, Settings.show_win_loss_ratio,
        Settings.player_card_count, Settings.player_draw_chance,
        Settings.player_cards_top, Settings.player_cards_bottom, Settings.hide_player_sideboards,
        Settings.opponent_card_count, Settings.opponent_draw_chance,
        Settings.show_opponent_class, Settings.opponent_related_cards,
        Settings.hide_opponent_arena_packages
    ]

    override func setUp() {
        super.setUp()
        let defaults = UserDefaults.standard
        for key in Self.keys {
            saved[key] = defaults.object(forKey: key)
        }
        // A known baseline, so a developer's own settings cannot change the
        // outcome of any of these.
        Settings.cardSize = .big
        Settings.showDeckNameInTracker = true
        Settings.showWinLossRatio = true
        Settings.showPlayerCardCount = true
        Settings.showPlayerDrawChance = true
        Settings.showPlayerCardsTop = true
        Settings.showPlayerCardsBottom = true
        Settings.hidePlayerSideboards = false
        Settings.showOpponentCardCount = true
        Settings.showOpponentDrawChance = true
        Settings.showOpponentClassInTracker = true
        Settings.showOpponentRelatedCards = true
        Settings.hideOpponentArenaPackages = false
        Settings.deckPanelOrderPlayer = DeckPanel.defaultPlayerOrder.map { $0.rawValue }
        Settings.deckPanelOrderOpponent = DeckPanel.defaultOpponentOrder.map { $0.rawValue }
        Settings.overlayPlayerScaling = 100
        Settings.overlayOpponentScaling = 100
    }

    override func tearDown() {
        let defaults = UserDefaults.standard
        for (key, value) in saved {
            if let value {
                defaults.set(value, forKey: key)
            } else {
                defaults.removeObject(forKey: key)
            }
        }
        saved.removeAll()
        super.tearDown()
    }

    // MARK: - Helpers

    private func cards(_ count: Int) -> [Card] {
        (0..<count).map { index in
            let card = Card()
            card.id = "TEST_\(index)"
            card.count = 1
            return card
        }
    }

    private func playerModel(deck: Int = 0, top: Int = 0, bottom: Int = 0,
                             height: Double = 88) -> TrackerPanelViewModel {
        let model = TrackerPanelViewModel(playerType: .player)
        model.update(cards: cards(deck), top: cards(top), bottom: cards(bottom),
                     sideboards: [], relatedCards: [])
        model.playerClassId = "HERO_01"
        model.height = height
        model.panelOrder = DeckPanel.order(for: .player)
        return model
    }

    private func kinds(_ layout: TrackerPanelLayout) -> [TrackerPanelLayout.Kind] {
        layout.sections.map { $0.kind }
    }

    // MARK: - Order

    func testPlayerSectionsFollowHDTDefaultOrder() {
        let model = playerModel(deck: 5, top: 1, bottom: 1)
        model.showGraveyard = true
        let layout = TrackerPanelLayout(viewModel: model, canvasHeight: 1080)

        XCTAssertEqual(kinds(layout), [
            .deckPanel(.deckTitle), .deckPanel(.wins), .deckPanel(.cardsTop), .deckPanel(.cards),
            .deckPanel(.cardsBottom), .deckPanel(.cardCounter), .deckPanel(.drawChances),
            .deckPanel(.graveyard)
        ])
    }

    func testSavedOrderIsHonoured() {
        Settings.deckPanelOrderPlayer = [DeckPanel.drawChances, .cardCounter, .cards, .deckTitle]
            .map { $0.rawValue }
        let model = playerModel(deck: 3)
        let layout = TrackerPanelLayout(viewModel: model, canvasHeight: 1080)

        // The saved order comes first; anything it predates is appended in the
        // default order's own sequence, so nothing silently goes missing.
        XCTAssertEqual(Array(kinds(layout).prefix(4)), [
            .deckPanel(.drawChances), .deckPanel(.cardCounter), .deckPanel(.cards), .deckPanel(.deckTitle)
        ])
        XCTAssertTrue(kinds(layout).contains(.deckPanel(.wins)))
    }

    func testHiddenSectionsAreLeftOut() {
        Settings.showWinLossRatio = false
        Settings.showPlayerCardCount = false
        let model = playerModel(deck: 3)
        let layout = TrackerPanelLayout(viewModel: model, canvasHeight: 1080)

        XCTAssertFalse(kinds(layout).contains(.deckPanel(.wins)))
        XCTAssertFalse(kinds(layout).contains(.deckPanel(.cardCounter)))
        XCTAssertTrue(kinds(layout).contains(.deckPanel(.cards)))
    }

    func testEmptyLensesAreLeftOut() {
        let model = playerModel(deck: 3, top: 0, bottom: 0)
        let layout = TrackerPanelLayout(viewModel: model, canvasHeight: 1080)

        XCTAssertFalse(kinds(layout).contains(.deckPanel(.cardsTop)))
        XCTAssertFalse(kinds(layout).contains(.deckPanel(.cardsBottom)))
    }

    /// HDT appends OpponentPackageCardsDeckLens and then OpponentRelatedCardsDeckLens
    /// after whatever DeckPanelOrderOpponent says (OverlayWindow.UpdateOpponentLayout).
    func testOpponentLensesComeAfterTheOrderedSections() {
        let model = TrackerPanelViewModel(playerType: .opponent)
        model.update(cards: cards(4), top: [], bottom: [], sideboards: [],
                     relatedCards: cards(2), packageCards: cards(1), packageLabel: "pkg")
        model.playerClassId = "HERO_02"
        model.panelOrder = DeckPanel.order(for: .opponent)
        let layout = TrackerPanelLayout(viewModel: model, canvasHeight: 1080)

        XCTAssertEqual(kinds(layout), [
            .deckPanel(.deckTitle), .deckPanel(.cards), .deckPanel(.cardCounter),
            .deckPanel(.drawChances), .packageLens, .relatedLens
        ])
    }

    /// The opponent has no top/bottom/sideboard sections, and a saved order that
    /// names them must not resurrect them.
    func testOpponentOrderDropsPlayerOnlySections() {
        Settings.deckPanelOrderOpponent = [DeckPanel.cardsTop, .cards, .sideboards, .cardCounter]
            .map { $0.rawValue }
        let order = DeckPanel.order(for: .opponent)

        XCTAssertFalse(order.contains(.cardsTop))
        XCTAssertFalse(order.contains(.sideboards))
        XCTAssertEqual(Array(order.prefix(2)), [.cards, .cardCounter])
    }

    // MARK: - Sizing

    /// PlayerStackHeight = (PlayerDeckHeight / 100 * Height) / (OverlayPlayerScaling / 100)
    func testBoxHeightFollowsHDTsStackHeight() {
        Settings.overlayPlayerScaling = 50
        let model = playerModel(deck: 1)
        model.scaling = 50
        let layout = TrackerPanelLayout(viewModel: model, canvasHeight: 1000)

        XCTAssertEqual(layout.boxHeight, 1000 * 0.88 / 0.5, accuracy: 0.001)
    }

    /// CardListHelper.AutoScaleCardTiles: the rows shrink until the stack fits.
    func testCardRowsShrinkToFitTheBox() {
        let model = playerModel(deck: 60, height: 40)
        let layout = TrackerPanelLayout(viewModel: model, canvasHeight: 1080)

        XCTAssertLessThan(layout.cardHeight, CGFloat(kRowHeight))
        let content = layout.sections.reduce(0) { $0 + $1.height }
        XCTAssertLessThanOrEqual(content, layout.boxHeight + 0.001)
    }

    /// ... and never past the card size the user picked, however much room there is.
    func testCardRowsNeverGrowPastTheChosenCardSize() {
        Settings.cardSize = .small
        let model = playerModel(deck: 2, height: 100)
        let layout = TrackerPanelLayout(viewModel: model, canvasHeight: 2000)

        XCTAssertEqual(layout.cardHeight, CGFloat(kSmallRowHeight), accuracy: 0.001)
    }

    /// The frame PNGs are authored at 217x40 (x71 for the opponent's chances) and
    /// drawn divided by the card size's ratio - see TextFrame.ratio.
    func testFrameHeightsFollowTheCardSizeRatio() {
        Settings.cardSize = .medium
        let model = playerModel(deck: 1)
        let layout = TrackerPanelLayout(viewModel: model, canvasHeight: 1080)

        XCTAssertEqual(layout.smallFrameHeight, (40 / CGFloat(CardSize.medium.ratio)).rounded())
        XCTAssertEqual(layout.bigFrameHeight, (71 / CGFloat(CardSize.medium.ratio)).rounded())
    }

    // MARK: - Section offsets

    func testSectionOffsetIsTheSumOfWhatPrecedesIt() {
        let model = playerModel(deck: 4)
        model.showGraveyard = true
        let layout = TrackerPanelLayout(viewModel: model, canvasHeight: 1080)

        guard let graveyard = layout.offset(of: .deckPanel(.graveyard), centered: false) else {
            return XCTFail("graveyard section missing")
        }
        var expected: CGFloat = 0
        for section in layout.sections {
            if section.kind == .deckPanel(.graveyard) { break }
            expected += section.height
        }
        XCTAssertEqual(graveyard.y, expected, accuracy: 0.001)
        XCTAssertEqual(graveyard.height, layout.smallFrameHeight, accuracy: 0.001)
    }

    /// OverlayCenterPlayerStackPanel, which HDT expresses as the stack's
    /// VerticalAlignment inside its fixed-height border.
    func testCenteredStackOffsetsEverySectionByHalfTheSlack() {
        let model = playerModel(deck: 2, height: 90)
        let layout = TrackerPanelLayout(viewModel: model, canvasHeight: 1080)
        let content = layout.sections.reduce(0) { $0 + $1.height }

        guard let top = layout.offset(of: layout.sections[0].kind, centered: true) else {
            return XCTFail("first section missing")
        }
        XCTAssertEqual(top.y, (layout.boxHeight - content) / 2, accuracy: 0.001)
    }

    // MARK: - Hosted AppKit sections

    /// The sections are the same AppKit views the window-based tracker used, and
    /// they lay their own children out from the frame they are given rather than
    /// in a layout pass of their own. This is the check that SwiftUI really does
    /// hand them that frame.
    func testHostedCardListGetsTheFrameTheLayoutComputed() {
        // No hero bar: it would need the card database, which this test does not
        // load, and it is not what is under test here.
        Settings.showDeckNameInTracker = false
        Settings.showWinLossRatio = false
        Settings.showPlayerCardCount = false
        Settings.showPlayerDrawChance = false

        let model = playerModel(deck: 6)
        model.isShown = true
        let canvas = CGSize(width: 1920, height: 1080)
        let layout = TrackerPanelLayout(viewModel: model, canvasHeight: canvas.height)

        let view = TrackerPanelView(viewModel: model,
                                    canvasSize: canvas,
                                    isLocked: true,
                                    hoverHandler: TrackerCardHoverHandler(playerType: .player))
        let host = NSHostingView(rootView: view)
        host.frame = CGRect(origin: .zero, size: canvas)
        host.layoutSubtreeIfNeeded()

        guard let list = firstDescendant(of: host, ofType: AnimatedCardList.self) else {
            return XCTFail("no AnimatedCardList was hosted")
        }
        XCTAssertEqual(list.frame.width, SizeHelper.trackerWidth, accuracy: 0.5)
        XCTAssertEqual(list.frame.height, CGFloat(6) * layout.cardHeight, accuracy: 0.5)
        XCTAssertEqual(list.count, 6)
        // updateFrames() ran, so every row is mounted and stacked.
        XCTAssertEqual(list.subviews.count, 6)
    }

    private func firstDescendant<T: NSView>(of view: NSView, ofType: T.Type) -> T? {
        for subview in view.subviews {
            if let match = subview as? T { return match }
            if let match = firstDescendant(of: subview, ofType: T.self) { return match }
        }
        return nil
    }
}
