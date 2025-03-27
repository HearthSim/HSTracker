//
//  PendantOfEarth.swift
//  HSTracker
//
//  Created by Francisco Moraes on 3/21/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

class PendantOfEarth: ICardWithHighlight {
    func getCardId() -> String {
        return CardIds.Collectible.Priest.PendantOfEarth
    }

    func shouldHighlight(card: Card) -> HighlightColor {
        return HighlightColorHelper.getHighlightColor(card.type == CardType.minion)
    }

    required init() {}
}
