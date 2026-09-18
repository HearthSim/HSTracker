//
//  OverlayWidgetPlacementTests.swift
//  HSTrackerTests
//
//  Created by Francisco Moraes on 9/17/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import SwiftUI
import XCTest
@testable import HSTracker

/// Dragging the counters and the active-effects tiles around the overlay, which
/// HDT does by adding the cursor delta to percentages of the client
/// (`OverlayWindow.Input.cs`) and saving them on mouse up.
@available(macOS 10.15, *)
class OverlayWidgetPlacementTests: HSTrackerTests {

    private var saved: [String: Any?] = [:]

    private static let keys = [
        Settings.player_counters_vertical, Settings.player_counters_horizontal,
        Settings.opponent_counters_vertical, Settings.opponent_counters_horizontal,
        Settings.player_active_effects_vertical, Settings.player_active_effects_horizontal,
        Settings.opponent_active_effects_vertical, Settings.opponent_active_effects_horizontal,
        Settings.attack_icon_player_vertical, Settings.attack_icon_player_horizontal,
        Settings.attack_icon_opponent_vertical, Settings.attack_icon_opponent_horizontal,
        Settings.player_max_resources_vertical, Settings.player_max_resources_horizontal,
        Settings.opponent_max_resources_vertical, Settings.opponent_max_resources_horizontal,
        Settings.timers_vertical_position, Settings.timers_horizontal_position,
        Settings.timers_vertical_spacing, Settings.timers_horizontal_spacing
    ]

    /// A 16:9 client, and the ratio `Helper.GetScaledXPos` spreads the horizontal
    /// percentage across: the 4:3 area is 75% of its width.
    private let canvas = CGSize(width: 1920, height: 1080)
    private let ratio: CGFloat = 0.75

    override func setUp() {
        super.setUp()
        let defaults = UserDefaults.standard
        for key in Self.keys {
            saved[key] = defaults.object(forKey: key)
            defaults.removeObject(forKey: key)
        }
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

    func testAPlacementStartsAtHearthstoneDeckTrackersOwnDefaults() {
        let counters = OverlayWidgetPlacement(widget: .counters, isPlayer: true)
        XCTAssertEqual(counters.vertical, 68.4)
        XCTAssertEqual(counters.horizontal, 67.7)

        let effects = OverlayWidgetPlacement(widget: .activeEffects, isPlayer: false)
        XCTAssertEqual(effects.vertical, 73.8)
        XCTAssertEqual(effects.horizontal, 66.2)

        // The three that used to be hard-coded constants in their own views, so
        // an overlay nobody has dragged still looks exactly as it did.
        let attackIcon = OverlayWidgetPlacement(widget: .attackIcon, isPlayer: true)
        XCTAssertEqual(attackIcon.vertical, 67.62)
        XCTAssertEqual(attackIcon.horizontal, 25.5)

        let resources = OverlayWidgetPlacement(widget: .maxResources, isPlayer: false)
        XCTAssertEqual(resources.vertical, 0.3)
        XCTAssertEqual(resources.horizontal, 72.2)

        let timers = OverlayWidgetPlacement(widget: .timers, isPlayer: true)
        XCTAssertEqual(timers.vertical, 44.5)
        XCTAssertEqual(timers.horizontal, 72)

        let spacing = OverlayWidgetPlacement(widget: .timerSpacing, isPlayer: true)
        XCTAssertEqual(spacing.vertical, 42)
        XCTAssertEqual(spacing.horizontal, 48)
    }

    /// Unlike the counters and the effects, both attack icons hang by their top
    /// edge, so neither side's drag flips sign.
    func testTheOpponentsAttackIconMovesTheSameWayAsThePlayers() {
        let player = OverlayWidgetPlacement(widget: .attackIcon, isPlayer: true)
        let opponent = OverlayWidgetPlacement(widget: .attackIcon, isPlayer: false)
        for placement in [player, opponent] {
            placement.drag(translation: CGSize(width: 0, height: 108),
                           canvasSize: canvas, ratio: ratio)
        }

        XCTAssertEqual(player.vertical, 67.62 + 10, accuracy: 0.001)
        XCTAssertEqual(opponent.vertical, 22.39 + 10, accuracy: 0.001)
    }

    /// The timers are the one element HDT places with the plain client width
    /// (`Width * TimersHorizontalPosition / 100`) rather than through
    /// `GetScaledXPos`, so their horizontal drag skips the ratio the others use.
    func testDraggingTheTimersUsesThePlainClientWidth() {
        let timers = OverlayWidgetPlacement(widget: .timers, isPlayer: true)
        timers.drag(translation: CGSize(width: 192, height: 108), canvasSize: canvas, ratio: ratio)

        XCTAssertEqual(timers.horizontal, 72 + 10, accuracy: 0.001)
        XCTAssertEqual(timers.vertical, 44.5 + 10, accuracy: 0.001)
    }

    /// Dragging the player's own timer moves only the pair either side of the
    /// middle one, and in points: the gap does not stretch with the client.
    func testDraggingThePlayerTimerMovesTheSpacingInPoints() {
        let spacing = OverlayWidgetPlacement(widget: .timerSpacing, isPlayer: true)
        spacing.drag(translation: CGSize(width: 12, height: -8), canvasSize: canvas, ratio: ratio)

        XCTAssertEqual(spacing.horizontal, 48 + 12, accuracy: 0.001)
        XCTAssertEqual(spacing.vertical, 42 - 8, accuracy: 0.001)
    }

    /// `PlayerCountersVertical += delta.Y / Height`, and the horizontal one
    /// divided by `Width * ScreenRatio` because the position goes through
    /// `Helper.GetScaledXPos`.
    func testDraggingThePlayersBlockMovesItWithTheCursor() {
        let placement = OverlayWidgetPlacement(widget: .counters, isPlayer: true)
        placement.drag(translation: CGSize(width: 144, height: 108),
                       canvasSize: canvas, ratio: ratio)

        XCTAssertEqual(placement.vertical, 68.4 + 10, accuracy: 0.001)
        XCTAssertEqual(placement.horizontal, 67.7 + 10, accuracy: 0.001)
    }

    /// The opponent's blocks hang by their bottom edge, so HDT *subtracts* there:
    /// `OpponentCountersVertical -= delta.Y / Height`. Dragging down has to lower
    /// the block all the same, which is what that sign does once the percentage
    /// is measured up from the bottom.
    func testDraggingTheOpponentsBlockCountsItsVerticalFromTheBottom() {
        let placement = OverlayWidgetPlacement(widget: .counters, isPlayer: false)
        placement.drag(translation: CGSize(width: 0, height: 108),
                       canvasSize: canvas, ratio: ratio)

        XCTAssertEqual(placement.vertical, 70.6 - 10, accuracy: 0.001)
    }

    /// SwiftUI reports the running total, so a gesture arriving in steps has to
    /// move the block exactly as far as the same gesture arriving in one.
    func testADragInStepsMovesAsFarAsTheSameDragInOne() {
        let stepped = OverlayWidgetPlacement(widget: .activeEffects, isPlayer: true)
        for height in stride(from: CGFloat(27), through: 108, by: 27) {
            stepped.drag(translation: CGSize(width: height, height: height),
                         canvasSize: canvas, ratio: ratio)
        }

        let once = OverlayWidgetPlacement(widget: .activeEffects, isPlayer: true)
        once.drag(translation: CGSize(width: 108, height: 108), canvasSize: canvas, ratio: ratio)

        XCTAssertEqual(stepped.vertical, once.vertical, accuracy: 0.001)
        XCTAssertEqual(stepped.horizontal, once.horizontal, accuracy: 0.001)
    }

    /// `MouseInputOnLmbUp` saves the config, and the next drag starts from a
    /// clean translation - otherwise it would jump by everything the last one
    /// covered.
    func testEndingADragSavesThePositionAndStartsTheNextOneFromRest() {
        let placement = OverlayWidgetPlacement(widget: .counters, isPlayer: true)
        placement.drag(translation: CGSize(width: 0, height: 108), canvasSize: canvas, ratio: ratio)
        placement.endDrag()

        XCTAssertEqual(Settings.playerCountersVertical, 78.4, accuracy: 0.001)
        XCTAssertEqual(OverlayWidgetPlacement(widget: .counters, isPlayer: true).vertical,
                       78.4, accuracy: 0.001)

        placement.drag(translation: CGSize(width: 0, height: 10.8), canvasSize: canvas, ratio: ratio)
        XCTAssertEqual(placement.vertical, 79.4, accuracy: 0.001)
    }
}
