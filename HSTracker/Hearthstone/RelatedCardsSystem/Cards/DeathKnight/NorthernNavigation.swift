//
//  NorthernNavigation.swift
//  HSTracker
//
//  Created by Francisco Moraes on 3/19/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class NorthernNavigation: ICardWithHighlight {
    required init() {
        
    }
    
    func getCardId() -> String {
        return CardIds.Collectible.Deathknight.NorthernNavigation
    }

    func shouldHighlight(card: Card) -> HighlightColor {
        let isFrostSpell = card.spellSchool == SpellSchool.frost
        let isSpell = card.type == CardType.spell
        return HighlightColorHelper.getHighlightColor(isFrostSpell, isSpell)
    }
}
