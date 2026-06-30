//
//  SmuggledShovel.swift
//  HSTracker
//
//  Created by Francisco Moraes on 6/30/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

class SmuggledShovel: ICardWithHighlight {

    required init() {}

    func getCardId() -> String {
        return CardIds.Collectible.Hunter.SmuggledShovel
    }

    func shouldHighlight(card: Card, deck: [Card]) -> HighlightColor {
        let matchesPattern = card.isCreated && card.type == .spell
        return HighlightColorHelper.getHighlightColor(matchesPattern)
    }
}
