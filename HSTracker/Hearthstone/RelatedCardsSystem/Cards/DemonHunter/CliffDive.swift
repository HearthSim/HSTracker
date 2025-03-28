//
//  CliffDive.swift
//  HSTracker
//
//  Created by Francisco Moraes on 3/19/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class CliffDive: ICardWithHighlight {
    required init() {
        
    }
    
    func getCardId() -> String {
        return CardIds.Collectible.DemonHunter.CliffDive
    }

    func shouldHighlight(card: Card, deck: [Card]) -> HighlightColor {
        return HighlightColorHelper.getHighlightColor(card.type == CardType.minion)
    }
}
