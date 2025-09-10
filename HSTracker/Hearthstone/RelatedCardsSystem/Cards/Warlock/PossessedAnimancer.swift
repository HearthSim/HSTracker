//
//  PossessedAnimancer.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/9/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class PossessedAnimancer: ICardWithHighlight {
    func getCardId() -> String {
        CardIds.Collectible.Warlock.PossessedAnimancer
    }

    func shouldHighlight(card: Card, deck: [Card]) -> HighlightColor {
        return HighlightColorHelper.getHighlightColor(card.isBeast())
    }

    required init() { }
}
