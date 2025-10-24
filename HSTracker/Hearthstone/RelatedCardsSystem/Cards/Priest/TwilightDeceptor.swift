//
//  TwilightDeceptor.swift
//  HSTracker
//
//  Created by Francisco Moraes on 10/24/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class TwilightDeceptor: ICardWithHighlight, ISpellSchoolTutor {
    func getCardId() -> String {
        return CardIds.Collectible.Priest.TwilightDeceptor
    }

    func shouldHighlight(card: Card, deck: [Card]) -> HighlightColor {
        return HighlightColorHelper.getHighlightColor(
            card.spellSchool == SpellSchool.shadow
        )
    }

    let tutoredSpellSchools: [Int] = [SpellSchool.shadow.rawValue]

    required init() {}
}
