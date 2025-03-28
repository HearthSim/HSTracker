//
//  GuitarSoloist.swift
//  HSTracker
//
//  Created by Francisco Moraes on 3/19/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class GuitarSoloist: ICardWithHighlight {
    required init() {
        
    }
    
    func getCardId() -> String {
        return CardIds.Collectible.DemonHunter.GuitarSoloist
    }

    func shouldHighlight(card: Card, deck: [Card]) -> HighlightColor {
        return HighlightColorHelper.getHighlightColor(
            card.type == CardType.spell,
            card.type == CardType.minion,
            card.type == CardType.weapon
        )
    }
}
