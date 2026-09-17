//
//  CardTileListView.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/17/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import SwiftUI

/// A deck list - HDT's `AnimatedCardList`, and the SwiftUI replacement for
/// HSTracker's `AnimatedCardList` inside the overlay.
///
/// The AppKit one diffs the incoming cards against the `CardBar`s it is holding,
/// fades a new one in from 0.3, fades a departing one out to 0.3 and drops it
/// 600ms later, and flashes a row whose count changed. SwiftUI does the first
/// three for free once the rows have stable identities, which is what `RowKey`
/// below is; the flash is driven by a token the list bumps.
@available(macOS 10.15, *)
struct CardTileListView: View {
    let cards: [Card]
    let playerType: PlayerType
    let cardHeight: CGFloat
    /// Suppresses the fade-in - HDT's `reset`, which rebuilds the list rather than
    /// animating into it (a new game, not a card drawn).
    var reset: Bool = false
    /// The rows whose count just changed, which flash - `CardBar.update(highlight:)`.
    var flashing: Set<RowKey> = []
    /// Bumped with every update, so a row that flashes twice running re-triggers.
    var version: Int = 0
    /// Which hover these rows raise - see `TrackerRowHoverKind`.
    var hoverKind: TrackerRowHoverKind = .none

    var body: some View {
        VStack(spacing: 0) {
            ForEach(rows, id: \.key) { row in
                CardTileView(card: row.card, playerType: playerType, rowHeight: cardHeight,
                             flashToken: flashing.contains(row.key) ? version : 0)
                    .background(
                        GeometryReader { proxy in
                            Color.clear.preference(
                                key: TrackerRowHoverKey.self,
                                value: hoverKind == .none
                                ? []
                                : [TrackerRowHover(rect: proxy.frame(in: .rootOverlayCanvas),
                                                   card: row.card, kind: hoverKind)])
                        }
                    )
                    .transition(.opacity)
            }
        }
        // The 10.15 form: there is no .animation(_:value:) before macOS 11, and
        // every change this list sees is a card arriving or leaving.
        .animation(reset ? nil : .easeInOut(duration: 0.5))
    }

    private var rows: [Row] {
        cards.map { Row(key: RowKey($0), card: $0) }
    }

    private struct Row {
        let key: RowKey
        let card: Card
    }
}

/// What makes two rows "the same card" - `AnimatedCardList.areEqualForList`.
///
/// A row keeps its identity, and so does not re-animate, while these hold; change
/// any of them and SwiftUI treats it as a different row, which is exactly when
/// the AppKit list would have swapped the `CardBar` out.
struct RowKey: Hashable {
    let id: String
    let jousted: Bool
    let isCreated: Bool
    let wasDiscarded: Bool
    let deckListIndex: Int
    let incindiusTurn: Int
    let incindiusCounter: Int

    init(_ card: Card) {
        id = card.id
        jousted = card.jousted
        isCreated = card.isCreated
        // Only part of a row's identity while the setting that draws it is on.
        wasDiscarded = Settings.highlightDiscarded ? card.wasDiscarded : false
        deckListIndex = card.deckListIndex
        let incindius = card.extraInfo as? IncindiusCounter
        incindiusTurn = incindius?.turnPlayed ?? -1
        incindiusCounter = incindius?.counter ?? -1
    }
}
