//
//  Moragg.swift
//  HSTracker
//
//  Created by Francisco Moraes on 6/30/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

class Moragg: ICardWithHighlight {

    required init() {}

    func getCardId() -> String {
        return CardIds.Collectible.Warlock.Moragg
    }

    func shouldHighlight(card: Card, deck: [Card]) -> HighlightColor {
        return HighlightColorHelper.getHighlightColor(card.isDemon())
    }
}
