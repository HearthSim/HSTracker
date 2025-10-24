//
//  HarbingerOfWinter.swift
//  HSTracker
//
//  Created by Francisco Moraes on 3/19/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class HarbingerOfWinter: ICardWithHighlight, ISpellSchoolTutor {
    required init() {
        
    }
    
    func getCardId() -> String {
        return CardIds.Collectible.Deathknight.HarbingerOfWinterCore
    }

    func shouldHighlight(card: Card, deck: [Card]) -> HighlightColor {
        let isFrostSpell = card.spellSchool == SpellSchool.frost
        return HighlightColorHelper.getHighlightColor(isFrostSpell)
    }
    
    var tutoredSpellSchools: [Int] {
        return [SpellSchool.frost.rawValue]
    }
}

class HarbingerOfWinterCore: HarbingerOfWinter {
    override func getCardId() -> String {
        return CardIds.NonCollectible.Deathknight.HarbingerOfWinterCore
    }
}
