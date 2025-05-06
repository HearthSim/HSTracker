//
//  LivingFlame.swift
//  HSTracker
//
//  Created by Francisco Moraes on 5/6/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class LivingFlame: ICardWithHighlight {
    required init() {
        
    }
    
    func getCardId() -> String {
        return CardIds.Collectible.Neutral.LivingFlame
    }

    func shouldHighlight(card: Card, deck: [Card]) -> HighlightColor {
        return HighlightColorHelper.getHighlightColor(
            card.spellSchool == SpellSchool.fire
        )
    }
}
