//
//  MulliganCardPortraitView.swift
//  HSTracker
//
//  Created by Francisco Moraes on 8/7/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import SwiftUI

@available(macOS 10.15, *)
struct MulliganCardPortraitView: View {
    let card: Card?

    @SwiftUI.State private var image: NSImage?

    init(card: Card?) {
        self.card = card
    }

    var body: some View {
        Circle()
            .fill(Color.black.opacity(0.4))
            .overlay(
                Group {
                    if let image {
                        Image(nsImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            // Matches HDT's ScaleTransform(1.6, 1.6, 16, 12) on its
                            // 32x32 portrait ellipse - zooms into the art crop so
                            // the card frame/edges don't show inside the circle.
                            .scaleEffect(1.6, anchor: UnitPoint(x: 0.5, y: 0.375))
                    }
                }
            )
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.black, lineWidth: 2))
            .onAppear(perform: load)
    }

    private func load() {
        guard let card else { return }
        // HDT's Portrait asset source is the plain art-only crop
        // (art.hearthstonejson.com/v1/256x/{id}.jpg), i.e. ImageUtils' `.art`
        // type - not `.cardArt`, which renders the full card (frame, text,
        // cost gem) and was showing the whole card squeezed into the circle.
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
