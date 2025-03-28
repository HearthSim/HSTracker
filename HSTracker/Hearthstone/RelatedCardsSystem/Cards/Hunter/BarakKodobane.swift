//
//  BarakKodobane.swift
//  HSTracker
//
//  Created by Francisco Moraes on 3/21/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

class BarakKodobane: ICardWithHighlight {
    func getCardId() -> String {
        return CardIds.Collectible.Hunter.BarakKodobane
    }

    func shouldHighlight(card: Card, deck: [Card]) -> HighlightColor {
        return HighlightColorHelper.getHighlightColor(
            (card.type == CardType.spell && card.cost == 1),
            (card.type == CardType.spell && card.cost == 2),
            (card.type == CardType.spell && card.cost == 3)
        )
    }

    required init() {}
}

class BarakKodobaneCore: BarakKodobane {
    override func getCardId() -> String {
        return CardIds.Collectible.Hunter.BarakKodobaneCore
    }
}
