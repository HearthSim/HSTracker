//
//  PipsiPainthoof.swift
//  HSTracker
//
//  Created by Francisco Moraes on 3/24/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class PipsiPainthoof: ICardWithHighlight {
    required init() {}
    
    func getCardId() -> String {
        return CardIds.Collectible.Paladin.PipsiPainthoof
    }
    
    func shouldHighlight(card: Card) -> HighlightColor {
        return HighlightColorHelper.getHighlightColor(
            card.mechanics.contains("DIVINE_SHIELD"),
            card.mechanics.contains("RUSH"),
            card.mechanics.contains("TAUNT")
        )
    }
}
