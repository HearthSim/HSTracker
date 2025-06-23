//
//  ScourgeIllusionist.swift
//  HSTracker
//
//  Created by Francisco Moraes on 6/23/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class ScourgeIllusionist: ICardWithHighlight {
    required init() {}

    func getCardId() -> String {
        CardIds.Collectible.Rogue.ScourgeIllusionist
    }

    func shouldHighlight(card: Card, deck: [Card]) -> HighlightColor {
        HighlightColorHelper.getHighlightColor(card.hasDeathrattle() && card.type == .minion && card.id != getCardId())
    }
}
