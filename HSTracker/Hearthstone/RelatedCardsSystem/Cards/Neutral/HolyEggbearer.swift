//
//  HolyEggbearer.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/9/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class HolyEggbearer: ICardWithHighlight {
    func getCardId() -> String {
        CardIds.Collectible.Neutral.HolyEggbearer
    }

    func shouldHighlight(card: Card, deck: [Card]) -> HighlightColor {
        return HighlightColorHelper.getHighlightColor(
            card.type == CardType.minion && card.attack == 0
        )
    }

    required init() { }
}
