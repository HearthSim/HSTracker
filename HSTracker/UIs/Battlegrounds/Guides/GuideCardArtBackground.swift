//
//  GuideCardArtBackground.swift
//  HSTracker
//
//  Created by Francisco Moraes on 8/13/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import SwiftUI

// Mirrors HDT's CompButton.xaml/CompGuide.xaml faded card-art background: an
// ImageBrush (Stretch="None", offset -30 in X) masked by a horizontal
// gradient that fades the art out toward the right so overlaid text stays
// legible. Reused for both the comp list row (opacity toggles on hover) and
// the comp/hero/quest detail header (fixed opacity) - same recipe already
// shipping in the sibling Arenasmith app.
//
// Callers must follow this with .clipped() on the container - the loaded
// art is shown at native pixel size (no .resizable(), matching HDT's
// Stretch="None") and is deliberately allowed to overflow its container
// before clipping, exactly like the WPF Rectangle it mirrors.
@available(macOS 10.15, *)
struct GuideCardArtBackground: View {
    let card: Card?
    var opacity: Double = 0.4
    // HDT's CompButton.xaml row fades out by 0.70; CompGuide.xaml's detail
    // header fades out further, by 0.80 - only the alpha of the gradient
    // stops matters for a .mask(), so the opaque stop's actual color here is
    // arbitrary.
    var gradientEnd: CGFloat = 0.70

    @SwiftUI.State private var image: NSImage?

    var body: some View {
        Group {
            if let image {
                Image(nsImage: image)
                    .offset(x: -30, y: 0)
                    .mask(
                        LinearGradient(
                            colors: [Color.black, Color.clear],
                            startPoint: UnitPoint(x: 0, y: 0),
                            endPoint: UnitPoint(x: gradientEnd, y: 0)
                        )
                    )
                    .opacity(opacity)
            }
        }
        .onAppear(perform: load)
    }

    private func load() {
        guard let card else { return }
        if let cached = ImageUtils.cachedArt(cardId: card.id) {
            image = cached
            return
        }
        ImageUtils.art(for: card.id) { img in
            DispatchQueue.main.async {
                self.image = img
            }
        }
    }
}
