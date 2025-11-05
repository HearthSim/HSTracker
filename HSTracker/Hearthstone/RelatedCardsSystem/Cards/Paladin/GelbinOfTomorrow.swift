//
//  GelbinOfTomorrow.swift
//  HSTracker
//
//  Created by Francisco Moraes on 11/4/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

class GelbinOfTomorrow: ICardWithHighlight {
    func getCardId() -> String {
        CardIds.Collectible.Paladin.GelbinOfTomorrow
    }

    func shouldHighlight(card: Card, deck: [Card]) -> HighlightColor {
        HighlightColorHelper.getHighlightColor(card.mechanics.contains("PALADIN_AURA"))
    }

    required init() {}
}
