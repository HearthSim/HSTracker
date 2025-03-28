//
//  EmbraceOfNature.swift
//  HSTracker
//
//  Created by Francisco Moraes on 3/20/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class EmbraceOfNature: ICardWithHighlight {
    required init() {
        
    }
    
    func getCardId() -> String {
        return CardIds.Collectible.Druid.EmbraceOfNature
    }

    func shouldHighlight(card: Card, deck: [Card]) -> HighlightColor {
        return HighlightColorHelper.getHighlightColor(card.mechanics.contains("CHOOSE_ONE"))
    }
}
