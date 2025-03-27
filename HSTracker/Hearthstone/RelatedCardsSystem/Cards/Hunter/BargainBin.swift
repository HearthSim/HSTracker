//
//  BargainBin.swift
//  HSTracker
//
//  Created by Francisco Moraes on 3/21/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

class BargainBin: ICardWithHighlight {
    func getCardId() -> String {
        return CardIds.Collectible.Hunter.BargainBin
    }

    func shouldHighlight(card: Card) -> HighlightColor {
        return HighlightColorHelper.getHighlightColor(
            card.type == CardType.spell,
            card.type == CardType.minion,
            card.type == CardType.weapon
        )
    }

    required init() {}
}
