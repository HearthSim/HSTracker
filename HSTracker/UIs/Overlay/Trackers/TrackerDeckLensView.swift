//
//  TrackerDeckLensView.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/17/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import SwiftUI

/// Ports HDT's `DeckLensIcon`.
enum DeckLensIcon {
    case lens, arenasmith
}

/// HDT's `DeckLens`: a labelled box holding a short list of cards - the cards on
/// top of the deck, the ones on the bottom, the opponent's related cards, their
/// arena package, and the Overdrawn void.
///
/// The SwiftUI replacement for the `DeckLens` NSStackView, whose chrome was an
/// NSBox with an NSImageView and an NSTextField laid out by hand.
@available(macOS 10.15, *)
struct TrackerDeckLensView: View {
    let cards: [Card]
    let label: String
    var icon: DeckLensIcon = .lens
    var isPremium = false
    let playerType: PlayerType
    let cardHeight: CGFloat
    /// The header's height, which is the tracker's own frame height.
    let frameHeight: CGFloat
    var reset = false
    var flashing: Set<RowKey> = []
    var version = 0
    var hoverKind: TrackerRowHoverKind = .none

    /// `HSReplayNetPremiumGold` from HDT's App.xaml.
    static let premiumGold = Color(red: 1, green: 0.690, blue: 0.051)
    /// `DeckLens`'s NSBox fill.
    static let background = Color(red: 0x23 / 255, green: 0x27 / 255, blue: 0x2A / 255)

    var body: some View {
        VStack(spacing: 0) {
            header
            CardTileListView(cards: cards, playerType: playerType, cardHeight: cardHeight,
                             reset: reset, flashing: flashing, version: version,
                             hoverKind: hoverKind)
            // DeckLens leaves five points below the list, inside the box.
            Spacer(minLength: 5).frame(height: 5)
        }
        .frame(width: SizeHelper.trackerWidth)
        .background(Self.background)
    }

    private var header: some View {
        HStack(spacing: 5) {
            iconView
            Text(verbatim: label)
                .font(.system(size: 13))
                .foregroundColor(isPremium ? Self.premiumGold : .white)
                .lineLimit(1)
            Spacer(minLength: 0)
        }
        .padding(.leading, 5)
        .frame(height: frameHeight)
    }

    /// HDT keeps both glyphs in the control and collapses one; here the view just
    /// swaps them, along with the size each is drawn at in DeckLens.xaml.
    @ViewBuilder
    private var iconView: some View {
        switch icon {
        case .lens:
            Image(nsImage: NSImage(named: "icon_magnifying_glass") ?? NSImage())
                .resizable()
                .renderingMode(.template)
                .foregroundColor(isPremium ? Self.premiumGold : .white)
                .frame(width: 17, height: 17)
        case .arenasmith:
            // The mark is 74x42 and DeckLens.xaml draws it in a 19x12 box; WPF's
            // Image stretches Uniform, so fit rather than distort.
            Image(nsImage: NSImage(named: "arenasmith-logo") ?? NSImage())
                .resizable()
                .renderingMode(.template)
                .aspectRatio(contentMode: .fit)
                .foregroundColor(isPremium ? Self.premiumGold : .white)
                .frame(width: 19, height: 12)
        }
    }
}

/// HDT's `DeckSideboards`: one labelled box per sideboard the deck carries -
/// E.T.C.'s band and King of the Underbelly's - which is the SwiftUI replacement
/// for the `DeckSideboards` NSStackView.
@available(macOS 10.15, *)
struct TrackerSideboardsView: View {
    let sideboards: [Sideboard]
    let playerType: PlayerType
    let cardHeight: CGFloat
    let frameHeight: CGFloat
    var reset = false
    var hoverKind: TrackerRowHoverKind = .none

    var body: some View {
        VStack(spacing: 0) {
            ForEach(boxes, id: \.ownerCardId) { sideboard in
                box(sideboard)
            }
        }
        .frame(width: SizeHelper.trackerWidth)
    }

    /// `DeckSideboards` draws King of the Underbelly's box above E.T.C.'s.
    private var boxes: [Sideboard] {
        let kotu = sideboards.first { $0.ownerCardId == CardIds.Collectible.Hunter.KingOfTheUnderbelly }
        let etc = sideboards.first { $0.ownerCardId == CardIds.Collectible.Neutral.ETCBandManager }
        return [kotu, etc].compactMap { $0 }.filter { !$0.cards.isEmpty }
    }

    private func box(_ sideboard: Sideboard) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Text(verbatim: title(for: sideboard))
                    .font(.system(size: 13))
                    .foregroundColor(.white)
                    .lineLimit(1)
                Spacer(minLength: 0)
            }
            .padding(.leading, 5)
            .frame(height: frameHeight)
            CardTileListView(cards: sideboard.cards, playerType: playerType,
                             cardHeight: cardHeight, reset: reset, hoverKind: hoverKind)
        }
        .background(TrackerDeckLensView.background)
    }

    private func title(for sideboard: Sideboard) -> String {
        if sideboard.ownerCardId == CardIds.Collectible.Hunter.KingOfTheUnderbelly {
            return Cards.by(cardId: CardIds.Collectible.Hunter.KingOfTheUnderbelly)?.name
                ?? "King of the Underbelly"
        }
        return String.localizedString("DeckSideboard_Label_ETCBand", comment: "")
    }
}
