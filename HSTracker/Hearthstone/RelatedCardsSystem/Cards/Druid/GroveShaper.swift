//
//  GroveShaper.swift
//  HSTracker
//
//  Created by Francisco Moraes on 3/27/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class GroveShaper: ICardWithHighlight, ISpellSchoolTutor {
    required init() {
        
    }
    
    func getCardId() -> String {
        return CardIds.Collectible.Druid.GroveShaper
    }

    func shouldHighlight(card: Card, deck: [Card]) -> HighlightColor {
        return HighlightColorHelper.getHighlightColor(
            card.spellSchool == SpellSchool.nature
        )
    }
    
    var tutoredSpellSchools: [Int] {
        return [SpellSchool.nature.rawValue]
    }
}
