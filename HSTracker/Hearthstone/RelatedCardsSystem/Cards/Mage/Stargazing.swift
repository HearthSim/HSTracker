//
//  Stargazing.swift
//  HSTracker
//
//  Created by Francisco Moraes on 6/20/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class Stargazing: ICardWithHighlight {
    required init() {}

    func getCardId() -> String {
        CardIds.Collectible.Mage.Stargazing
    }

    func shouldHighlight(card: Card, deck: [Card]) -> HighlightColor {
        HighlightColorHelper.getHighlightColor(card.spellSchool == SpellSchool.arcane)
    }
}
