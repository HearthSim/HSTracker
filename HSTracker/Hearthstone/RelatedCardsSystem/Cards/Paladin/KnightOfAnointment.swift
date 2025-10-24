//
//  KnightOfAnointment.swift
//  HSTracker
//
//  Created by Francisco Moraes on 5/22/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class KnightOfAnointment: ICardWithHighlight, ISpellSchoolTutor {
    required init() {}

    func getCardId() -> String {
        return CardIds.Collectible.Paladin.KnightOfAnointment
    }

    func shouldHighlight(card: Card, deck: [Card]) -> HighlightColor {
        return HighlightColorHelper.getHighlightColor(
            card.spellSchool == SpellSchool.holy
        )
    }
    
    var tutoredSpellSchools: [Int] {
        return [SpellSchool.holy.rawValue]
    }
}
