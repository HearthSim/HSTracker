//
//  BattlegroundsSessionTileArt.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/9/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import SwiftUI

// The faded card tile HDT draws behind both a Latest Games row
// (BattlegroundsGameView.xaml) and a Composition Stats row
// (BattlegroundsCompositionStatsRow.xaml): a 145x34 tile under a horizontal
// OpacityMask that runs from the row's own background colour at the left edge
// to transparent at the right, so the text over it stays legible.
//
// Only the alpha of `fadeColor` matters - it is an opacity mask, not a tint -
// which is why the two call sites pass their XAML's literal stop colours
// (#AA000000 and #141617) rather than a bare opacity.
@available(macOS 10.15, *)
struct BattlegroundsSessionTileArt: View {
    let card: Card?
    let fadeColor: Color

    // Image Height="34" Width="145" in both XAMLs.
    private static let artWidth: CGFloat = 145
    private static let artHeight: CGFloat = 34

    @SwiftUI.State private var image: NSImage?

    var body: some View {
        Group {
            if let image {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: Self.artWidth, height: Self.artHeight)
                    .mask(
                        LinearGradient(
                            gradient: Gradient(colors: [fadeColor, Color.clear]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: Self.artWidth, height: Self.artHeight)
                    )
            } else {
                Color.clear
                    .frame(width: Self.artWidth, height: Self.artHeight)
            }
        }
        .onAppear(perform: load)
    }

    private func load() {
        guard let card else { return }
        if let cached = ImageUtils.cachedTile(cardId: card.id) {
            image = cached
            return
        }
        ImageUtils.tile(for: card.id) { img in
            DispatchQueue.main.async {
                self.image = img
            }
        }
    }
}
