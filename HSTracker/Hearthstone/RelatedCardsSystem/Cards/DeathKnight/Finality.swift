//
//  Finality.swift
//  HSTracker
//
//  Created by Francisco Moraes on 1/13/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

class Finality: ICardWithHighlight {

    required init() {}

    func getCardId() -> String {
        return CardIds.Collectible.Deathknight.Finality
    }

    func shouldHighlight(card: Card, deck: [Card]) -> HighlightColor {
        return HighlightColorHelper.getHighlightColor(card.isUndead())
    }
}
