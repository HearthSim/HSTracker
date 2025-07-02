//
//  HighCultistHerenn.swift
//  HSTracker
//
//  Created by Francisco Moraes on 7/2/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class HighCultistHerenn: ICardWithHighlight {
    required init() {}

    func getCardId() -> String {
        CardIds.Collectible.Deathknight.HighCultistHerenn
    }

    func shouldHighlight(card: Card, deck: [Card]) -> HighlightColor {
        HighlightColorHelper.getHighlightColor(
            card.type == .minion && card.hasDeathrattle()
        )
    }
}
