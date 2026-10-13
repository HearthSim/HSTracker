//
//  Efflorescence.swift
//  HSTracker
//
//  Created by Francisco Moraes on 10/13/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

// "Draw a different spell. If it's a Nature spell, it casts twice."
class Efflorescence: ICardWithHighlight {
    required init() {}

    func getCardId() -> String {
        CardIds.Collectible.Druid.Efflorescence
    }

    // Nature spells first: they are the ones that cast twice.
    func shouldHighlight(card: Card, deck: [Card]) -> HighlightColor {
        if card.id == getCardId() {
            return .none
        }
        return HighlightColorHelper.getHighlightColor(
            card.type == .spell && card.spellSchool == .nature,
            card.type == .spell
        )
    }
}
