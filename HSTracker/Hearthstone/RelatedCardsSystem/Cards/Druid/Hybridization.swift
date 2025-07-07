//
//  Hybridization.swift
//  HSTracker
//
//  Created by Francisco Moraes on 7/7/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class Hybridization: ICardWithHighlight {
    required init() {
        
    }
    
    func getCardId() -> String {
        CardIds.Collectible.Druid.Hybridization
    }

    func shouldHighlight(card: Card, deck: [Card]) -> HighlightColor {
        HighlightColorHelper.getHighlightColor(
            (card.type == .minion && (card.cost == 1 || card.cost == 4)),
            (card.type == .minion && card.cost == 2),
            (card.type == .minion && card.cost == 3)
        )
    }
}
