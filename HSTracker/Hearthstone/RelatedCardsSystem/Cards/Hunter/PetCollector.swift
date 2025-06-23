//
//  PetCollector.swift
//  HSTracker
//
//  Created by Francisco Moraes on 6/20/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class PetCollector: ICardWithHighlight {
    required init() {
    }
    
    func getCardId() -> String {
        CardIds.Collectible.Hunter.PetCollector
    }

    func shouldHighlight(card: Card, deck: [Card]) -> HighlightColor {
        HighlightColorHelper.getHighlightColor(card.isBeast() && card.cost <= 5)
    }
}
