//
//  CardTileThemeTests.swift
//  HSTrackerTests
//
//  Created by Francisco Moraes on 9/17/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import SwiftUI
import XCTest
@testable import HSTracker

/// Switching the card-bar theme has to redraw the rows that are already on
/// screen, which is what `CardTile.Subscribe`'s `ThemeManager.ThemeChanged`
/// handler does upstream.
///
/// The theme is not one of a row's own values, so SwiftUI has no reason to
/// re-run a row's body when it changes: a tracker update that hands back the
/// same `Card` at the same height compares equal and is skipped, art and all.
/// These render a row offscreen and compare the pixels, since that is the only
/// place the difference shows.
class CardTileThemeTests: HSTrackerTests {

    private var savedTheme: Any?

    override func setUp() {
        super.setUp()
        savedTheme = UserDefaults.standard.object(forKey: Settings.theme_token)
        Settings.theme = "dark"
    }

    override func tearDown() {
        if let savedTheme {
            UserDefaults.standard.set(savedTheme, forKey: Settings.theme_token)
        } else {
            UserDefaults.standard.removeObject(forKey: Settings.theme_token)
        }
        savedTheme = nil
        super.tearDown()
    }

    /// A card id nothing ships art for, so the only thing that can change
    /// between two renders of the same row is the theme.
    private func row() -> Card {
        let card = Card()
        card.id = "TEST_THEME_ROW"
        card.name = "Test Card"
        card.cost = 3
        card.count = 1
        return card
    }

    private func snapshot(_ view: NSView) -> Data? {
        view.layoutSubtreeIfNeeded()
        guard let rep = view.bitmapImageRepForCachingDisplay(in: view.bounds) else { return nil }
        view.cacheDisplay(in: view.bounds, to: rep)
        return rep.representation(using: .png, properties: [:])
    }

    /// The change is published on the main queue, and SwiftUI redraws on the
    /// run loop - so both need a turn of it before the next render.
    private func settle(_ seconds: TimeInterval = 0.3) {
        let waited = expectation(description: "settled")
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) { waited.fulfill() }
        wait(for: [waited], timeout: seconds + 2)
    }

    func testSwitchingThemeRedrawsARowAlreadyOnScreen() {
        let host = NSHostingView(rootView: CardTileView(card: row(), playerType: .player, rowHeight: 34))
        host.frame = NSRect(x: 0, y: 0, width: 217, height: 34)
        settle()

        let dark = snapshot(host)
        XCTAssertNotNil(dark)

        Settings.theme = "minimal"
        settle()

        XCTAssertNotEqual(dark, snapshot(host))
    }

    /// The counters under the list are framed by the same theme, and were as
    /// prone to keeping the old one: their numbers stand still for whole turns.
    func testSwitchingThemeRedrawsACounterFrameAlreadyOnScreen() {
        // classic -> frost, not the dark -> minimal the rows use: neither of
        // those two ships overlay frames of its own, so both draw the `default`
        // directory's and the render would be identical however it was redrawn.
        Settings.theme = "classic"
        let frame = TrackerFrameView(background: "card-counter-frame.png",
                                     box: CGSize(width: 217, height: 40), height: 40) {
            EmptyView()
        }
        let host = NSHostingView(rootView: frame)
        host.frame = NSRect(x: 0, y: 0, width: 217, height: 40)
        settle()

        let classic = snapshot(host)
        XCTAssertNotNil(classic)

        Settings.theme = "frost"
        settle()

        XCTAssertNotEqual(classic, snapshot(host))
    }
}
