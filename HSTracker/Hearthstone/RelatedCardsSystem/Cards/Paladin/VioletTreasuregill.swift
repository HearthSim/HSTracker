//
//  VioletTreasuregill.swift
//  HSTracker
//
//  Created by Francisco Moraes on 7/2/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class VioletTreasuregill: ICardWithHighlight {
    required init() {}

    func getCardId() -> String {
        CardIds.Collectible.Paladin.VioletTreasuregill
    }

    func shouldHighlight(card: Card, deck: [Card]) -> HighlightColor {
        HighlightColorHelper.getHighlightColor(card.type == .spell && card.cost <= 2)
    }
}
