//
//  Zerontu.swift
//  HSTracker
//
//  Created by Francisco Moraes on 10/13/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

// "Taunt. Battlecry: Summon a 0, 1, and 2-Attack minion from your deck. Gain their stats."
class Zerontu: ICardWithHighlight {
    required init() {}

    func getCardId() -> String {
        CardIds.Collectible.Priest.Zerontu
    }

    func shouldHighlight(card: Card, deck: [Card]) -> HighlightColor {
        HighlightColorHelper.getHighlightColor(
            card.type == .minion && card.attack == 0,
            card.type == .minion && card.attack == 1,
            card.type == .minion && card.attack == 2
        )
    }
}
