//
//  HeraldOfLokholar.swift
//  HSTracker
//
//  Created by Francisco Moraes on 10/24/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class HeraldOfLokholar: ICardWithHighlight, ISpellSchoolTutor {
    func getCardId() -> String {
        return CardIds.Collectible.Neutral.HeraldOfLokholar
    }

    func shouldHighlight(card: Card, deck: [Card]) -> HighlightColor {
        return HighlightColorHelper.getHighlightColor(
            card.spellSchool == SpellSchool.frost
        )
    }

    let tutoredSpellSchools: [Int] = [SpellSchool.frost.rawValue]

    required init() {}
}
