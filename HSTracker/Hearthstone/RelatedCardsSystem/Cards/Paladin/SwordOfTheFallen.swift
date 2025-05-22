//
//  SwordOfTheFallen.swift
//  HSTracker
//
//  Created by Francisco Moraes on 5/22/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class SwordOfTheFallen: ICardWithHighlight {
    required init() {}

    func getCardId() -> String {
        return CardIds.Collectible.Paladin.SwordOfTheFallen
    }

    func shouldHighlight(card: Card, deck: [Card]) -> HighlightColor {
        return HighlightColorHelper.getHighlightColor(card.mechanics.contains("SECRET"))
    }
}
