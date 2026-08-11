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
                    }
                }
            )
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.black, lineWidth: 2))
            .onAppear(perform: load)
    }

    private func load() {
        guard let card else { return }
        if let cached = ImageUtils.cachedArt(cardId: card.id) {
            image = cached
            return
        }
        ImageUtils.cardArt(for: card.id) { img in
            DispatchQueue.main.async {
                self.image = img
            }
        }
    }
}
