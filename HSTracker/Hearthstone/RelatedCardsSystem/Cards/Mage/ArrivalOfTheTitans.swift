//
//  ArrivalOfTheTitans.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/21/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

// "Draw 2 spells. Refresh 6 Mana Crystals. You can only play spells for the rest of the turn."
class ArrivalOfTheTitans: ICardWithHighlight {
    required init() {}

    func getCardId() -> String {
        CardIds.Collectible.Mage.ArrivalOfTheTitans
    }

    func shouldHighlight(card: Card, deck: [Card]) -> HighlightColor {
        HighlightColorHelper.getHighlightColor(card.type == .spell)
    }
}
