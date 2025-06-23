//
//  PebblyPage.swift
//  HSTracker
//
//  Created by Francisco Moraes on 6/23/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class PebblyPage: ICardWithHighlight {
    required init() {}

    func getCardId() -> String {
        CardIds.Collectible.Shaman.PebblyPage
    }

    func shouldHighlight(card: Card, deck: [Card]) -> HighlightColor {
        HighlightColorHelper.getHighlightColor(card.mechanics.contains("OVERLOAD"))
    }
}
