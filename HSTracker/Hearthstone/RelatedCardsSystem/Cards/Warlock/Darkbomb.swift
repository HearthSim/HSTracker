//
//  Darkbomb.swift
//  HSTracker
//
//  Created by Francisco Moraes on 6/23/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class Darkbomb: ICardWithHighlight, ISpellSchoolTutor {
    required init() {}

    func getCardId() -> String {
        CardIds.Collectible.Warlock.Darkbomb
    }

    func shouldHighlight(card: Card, deck: [Card]) -> HighlightColor {
        HighlightColorHelper.getHighlightColor(card.spellSchool == SpellSchool.shadow)
    }
    
    var tutoredSpellSchools: [Int] {
        return [SpellSchool.shadow.rawValue]
    }
}

class DarkbombWONDERS: Darkbomb {
    override func getCardId() -> String {
        CardIds.Collectible.Warlock.DarkbombWONDERS
    }
}
