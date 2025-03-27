//
//  Saruun.swift
//  HSTracker
//
//  Created by Francisco Moraes on 3/24/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class Saruun: ICardWithHighlight {
    required init() {}
    
    func getCardId() -> String {
        return CardIds.Collectible.Mage.Saruun
    }
    
    func shouldHighlight(card: Card) -> HighlightColor {
        return HighlightColorHelper.getHighlightColor(card.isElemental())
    }
}
