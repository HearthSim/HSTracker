//
//  ArenaCardImageGridView.swift
//  HSTracker
//
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import SwiftUI

/// A wrapped grid of full card images, scaled so the whole set fits the space it
/// is given. Port of HDT's `CardImageGrid`.
@available(macOS 10.15, *)
struct ArenaCardImageGridView: View {
    let cards: [Card]
    let columns: Int
    let maxWidth: CGFloat
    var maxCardHeight: CGFloat = 295

    // HDT's card art is 256x388 with a negative margin that overlaps neighbours,
    // trimming the transparent border the rendered images carry.
    private static let cardWidth: CGFloat = 256
    private static let cardHeight: CGFloat = 388
    private static let marginX: CGFloat = -2
    private static let marginY: CGFloat = -14

    private var spacedWidth: CGFloat { Self.cardWidth + Self.marginX * 2 }
    private var spacedHeight: CGFloat { Self.cardHeight + Self.marginY * 2 }

    /// Port of `CardImageGrid.Update`. HDT scales the whole wrap panel with a
    /// LayoutTransform rather than resizing each image, so the scale is solved
    /// once for the set.
    private var scale: CGFloat {
        let count = cards.count
        guard count > 0 else { return 1 }

        // 10pt of container margin, as HDT subtracts.
        let gridWidth = max(1, maxWidth - 10)
        let maxScale = min(1, maxCardHeight / Self.cardHeight)

        if count <= 3 {
            // HDT lays out up to three cards on one row regardless of `columns`.
            return min(maxScale, gridWidth / (spacedWidth * 3))
        }

        let cols = CGFloat(min(columns, count))
        guard cols > 0 else { return maxScale }
        return min(maxScale, gridWidth / (spacedWidth * cols))
    }

    /// How many fit per row once scaled - the wrap the grid actually performs.
    private var perRow: Int {
        max(1, min(columns, cards.count))
    }

    private var rows: [[Card]] {
        stride(from: 0, to: cards.count, by: perRow).map {
            Array(cards[$0..<min($0 + perRow, cards.count)])
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(rows.enumerated()), id: \.offset) { rowIndex, row in
                HStack(spacing: 0) {
                    ForEach(Array(row.enumerated()), id: \.offset) { columnIndex, card in
                        ArenaCardImageView(cardId: card.id)
                            // Identity has to change with the *card*, not just
                            // with the slot. The ForEach keys on position, so
                            // moving between two heroes hands slot N a new card
                            // id while keeping the same view - and its @State
                            // image, which is the previous card's art. The
                            // position stays in the id because a related-cards
                            // set can legitimately list the same card twice.
                            .id("\(rowIndex).\(columnIndex).\(card.id)")
                            .frame(width: Self.cardWidth, height: Self.cardHeight)
                            .padding(.horizontal, Self.marginX)
                            .padding(.vertical, Self.marginY)
                    }
                }
            }
        }
        // Scale the laid-out grid rather than each image, matching HDT's
        // LayoutTransform on the wrap panel.
        .scaleEffect(scale)
        .frame(width: CGFloat(perRow) * spacedWidth * scale,
               height: CGFloat(rows.count) * spacedHeight * scale)
    }
}

/// One full card image, loaded through the same cache the rest of the overlay uses.
@available(macOS 10.15, *)
struct ArenaCardImageView: View {
    let cardId: String

    @SwiftUI.State private var image: NSImage?

    init(cardId: String) {
        self.cardId = cardId
        // Seeded from the cache so an already-downloaded card draws on the first
        // frame instead of blanking until onAppear runs.
        _image = SwiftUI.State(initialValue: ImageUtils.cachedCardArt(cardId: cardId))
    }

    var body: some View {
        Group {
            if let image {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .shadow(color: .black.opacity(0.6), radius: 7, x: 4, y: 4)
            } else {
                // Placeholder keeps the slot's size while the art loads, so the
                // grid doesn't reflow when images arrive one at a time.
                Color.clear
            }
        }
        // The identity that matters is applied by the grid above: .id() here
        // would only re-identify this Group, leaving the enclosing view's @State
        // - and so the previous card's art - untouched.
        .onAppear(perform: load)
    }

    // The rendered card, not the square art crop: HDT binds the card's `Asset`,
    // which is the full frame with name, cost and text. `ImageUtils.art` is the
    // bare 256x256 artwork and reads as the wrong image entirely at this size.
    private func load() {
        if let cached = ImageUtils.cachedCardArt(cardId: cardId) {
            image = cached
            return
        }
        ImageUtils.cardArt(for: cardId) { img in
            DispatchQueue.main.async {
                self.image = img
            }
        }
    }
}
