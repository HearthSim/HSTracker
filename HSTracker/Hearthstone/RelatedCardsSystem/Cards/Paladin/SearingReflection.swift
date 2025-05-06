//
//  SearingReflection.swift
//  HSTracker
//
//  Created by Francisco Moraes on 5/6/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class SearingReflection: ICardWithHighlight {
    required init() {
        
    }
    
    func getCardId() -> String {
        return CardIds.Collectible.Paladin.SearingReflection
    }

    func shouldHighlight(card: Card, deck: [Card]) -> HighlightColor {
        return HighlightColorHelper.getHighlightColor(card.type == .minion)
    }
}
