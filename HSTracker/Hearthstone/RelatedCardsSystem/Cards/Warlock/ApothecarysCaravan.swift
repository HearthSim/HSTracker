//
//  ApothecarysCaravan.swift
//  HSTracker
//
//  Created by Francisco Moraes on 5/22/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class ApothecarysCaravan: ICardWithHighlight {
    required init() {}

    func getCardId() -> String {
        return CardIds.Collectible.Warlock.ApothecarysCaravan
    }

    func shouldHighlight(card: Card, deck: [Card]) -> HighlightColor {
        return HighlightColorHelper.getHighlightColor(card.type == .minion && card.cost == 1)
    }
}
