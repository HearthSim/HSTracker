//
//  TortollanTraveler.swift
//  HSTracker
//
//  Created by Francisco Moraes on 3/20/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class TortollanTraveler: ICardWithHighlight {
    required init() {
        
    }
    
    func getCardId() -> String {
        return CardIds.Collectible.Druid.TortollanTraveler
    }

    func shouldHighlight(card: Card, deck: [Card]) -> HighlightColor {
        return HighlightColorHelper.getHighlightColor(card.hasTaunt() && card.id != getCardId())
    }
}
