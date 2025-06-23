//
//  Felgorger.swift
//  HSTracker
//
//  Created by Francisco Moraes on 6/20/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class Felgorger: ICardWithHighlight {
    required init() {
    }
    
    func getCardId() -> String {
        CardIds.Collectible.DemonHunter.Felgorger
    }

    func shouldHighlight(card: Card, deck: [Card]) -> HighlightColor {
        HighlightColorHelper.getHighlightColor(card.spellSchool == SpellSchool.fel)
    }
}
