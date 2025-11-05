//
//  Solitude.swift
//  HSTracker
//
//  Created by Francisco Moraes on 11/4/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

class Solitude: ICardWithHighlight {
    func getCardId() -> String {
        CardIds.Collectible.DemonHunter.Solitude
    }

    func shouldHighlight(card: Card, deck: [Card]) -> HighlightColor {
        HighlightColorHelper.getHighlightColor(card.type == .minion)
    }

    required init() {}
}
