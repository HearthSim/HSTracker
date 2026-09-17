//
//  TrackerCardListContent.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/17/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import SwiftUI

/// What one of a tracker's card lists is showing.
///
/// `version` is bumped by the view model on every update, so a row that flashes
/// twice running can tell the two apart, and `reset` carries HDT's own `reset`
/// flag - a rebuild rather than an animated diff.
struct TrackerCardListContent {
    var cards: [Card] = []
    var version: Int = 0
    var reset: Bool = false
    /// The rows whose count changed in this update, which flash on draw the way
    /// `CardBar.update(highlight:)` made them - gated on `Settings.flashOnDraw`
    /// where it is drawn.
    var flashing: Set<RowKey> = []

    /// The rows that changed between two updates, which is what the AppKit list
    /// worked out while diffing (`existing.card?.count != card.count`).
    static func flashingRows(from previous: [Card], to cards: [Card]) -> Set<RowKey> {
        guard !previous.isEmpty else { return [] }
        var counts = [RowKey: Int]()
        for card in previous { counts[RowKey(card)] = card.count }
        return Set(cards.compactMap { card -> RowKey? in
            let key = RowKey(card)
            guard let was = counts[key], was != card.count else { return nil }
            return key
        })
    }
}

/// One hoverable row, reported up to `RootOverlayWindow` so it can raise that
/// card's preview from the cursor position.
///
/// The rows used to be `CardBar`s with `NSTrackingArea`s, which a click-through
/// overlay window never delivers events to - so the sweep walked the hosted
/// lists' subviews instead. Now that they are SwiftUI they have no views to walk,
/// and they report themselves the way every other hover-visible child of the
/// canvas does. This stays a sweep rather than `.onHover` for the same reason as
/// before: `.onHover` only fires once the window has stopped being click-through,
/// and HDT's deck lists never stop being.
@available(macOS 10.15, *)
struct TrackerRowHover: Equatable {
    /// The row's frame in canvas pixels.
    let rect: CGRect
    let card: Card
    /// Who to tell. Not derived from the row's `playerType`: the secret helper and
    /// the graveyard list draw `.secrets` rows but want the plain card preview,
    /// not the deck tracker's related-cards grid and synergy highlight.
    let kind: TrackerRowHoverKind

    static func == (lhs: TrackerRowHover, rhs: TrackerRowHover) -> Bool {
        lhs.rect == rhs.rect && lhs.card === rhs.card && lhs.kind == rhs.kind
    }
}

/// Which hover a list's rows raise.
enum TrackerRowHoverKind: Equatable {
    case playerDeck
    case opponentDeck
    /// The standalone lists beside a tracker - the secret helper (whose preview is
    /// pinned to its right, as `CardList.isSecretPanel` pinned it) and the
    /// graveyard details.
    case secrets
    case cardList
    /// Rows that raise nothing.
    case none
}

/// What a hovered row is reported to.
@available(macOS 10.15, *)
protocol TrackerRowHoverTarget: AnyObject {
    /// `rowFrame` is in screen coordinates.
    func hover(card: Card, rowFrame: NSRect)
    func out(card: Card)
}

@available(macOS 10.15, *)
struct TrackerRowHoverKey: PreferenceKey {
    static var defaultValue: [TrackerRowHover] = []
    static func reduce(value: inout [TrackerRowHover], nextValue: () -> [TrackerRowHover]) {
        value.append(contentsOf: nextValue())
    }
}
