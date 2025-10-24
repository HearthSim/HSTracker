//
//  BlazingAccretion.swift
//  HSTracker
//
//  Created by Francisco Moraes on 3/24/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class BlazingAccretion: ICardWithHighlight, ISpellSchoolTutor {
    required init() {}
    
    func getCardId() -> String {
        return CardIds.Collectible.Mage.BlazingAccretion
    }
    
    func shouldHighlight(card: Card, deck: [Card]) -> HighlightColor {
        return HighlightColorHelper.getHighlightColor(
            card.spellSchool == SpellSchool.fire ||
            card.isElemental()
        )
    }
    
    var tutoredSpellSchools: [Int] {
        return [SpellSchool.fire.rawValue]
    }
}
