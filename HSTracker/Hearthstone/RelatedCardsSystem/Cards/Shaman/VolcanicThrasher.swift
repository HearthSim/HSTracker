//
//  VolcanicThrasher.swift
//  HSTracker
//
//  Created by Francisco Moraes on 7/2/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class VolcanicThrasher: ICardWithHighlight {
    required init() {}

    func getCardId() -> String {
        CardIds.Collectible.Shaman.VolcanicThrasher
    }

    func shouldHighlight(card: Card, deck: [Card]) -> HighlightColor {
        HighlightColorHelper.getHighlightColor(card.spellSchool == SpellSchool.fire)
    }
}
