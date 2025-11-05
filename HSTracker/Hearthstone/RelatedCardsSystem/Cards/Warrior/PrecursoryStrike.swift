//
//  PrecursoryStrike.swift
//  HSTracker
//
//  Created by Francisco Moraes on 11/4/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

class PrecursoryStrike: ICardWithHighlight {
    func getCardId() -> String {
        CardIds.Collectible.Warrior.PrecursoryStrike
    }

    func shouldHighlight(card: Card, deck: [Card]) -> HighlightColor {
        HighlightColorHelper.getHighlightColor(card.type == .minion)
    }

    required init() {}
}
