//
//  Fatebreaker.swift
//  HSTracker
//
//  Created by Francisco Moraes on 11/4/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

class Fatebreaker: ICardWithHighlight {
    func getCardId() -> String {
        CardIds.Collectible.Warlock.Fatebreaker
    }

    func shouldHighlight(card: Card, deck: [Card]) -> HighlightColor {
        HighlightColorHelper.getHighlightColor(card.id == CardIds.NonCollectible.Warlock.TwilightTimehopper_ShredOfTimeToken)
    }

    required init() {}
}
