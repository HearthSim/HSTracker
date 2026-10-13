//
//  DiscsOfNorgannon.swift
//  HSTracker
//
//  Created by Francisco Moraes on 10/13/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

// "Move all spells in your deck to the top. You can pick to draw from the top or bottom each turn."
class DiscsOfNorgannon: ICardWithHighlight {
    required init() {}

    func getCardId() -> String {
        CardIds.Collectible.Mage.DiscsOfNorgannon
    }

    func shouldHighlight(card: Card, deck: [Card]) -> HighlightColor {
        HighlightColorHelper.getHighlightColor(card.type == .spell)
    }
}
