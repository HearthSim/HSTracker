//
//  FrostweaveDungeoneer.swift
//  HSTracker
//
//  Created by Francisco Moraes on 6/20/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class FrostweaveDungeoneer: ICardWithHighlight {
    required init() {}

    func getCardId() -> String {
        CardIds.Collectible.Mage.FrostweaveDungeoneer
    }

    func shouldHighlight(card: Card, deck: [Card]) -> HighlightColor {
        HighlightColorHelper.getHighlightColor(
            card.spellSchool == SpellSchool.frost &&
            card.type == .spell
        )
    }
}
