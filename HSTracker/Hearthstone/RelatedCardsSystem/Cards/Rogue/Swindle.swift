//
//  Swindle.swift
//  HSTracker
//
//  Created by Francisco Moraes on 6/23/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class Swindle: ICardWithHighlight {
    required init() {}

    func getCardId() -> String {
        CardIds.Collectible.Rogue.Swindle
    }

    func shouldHighlight(card: Card, deck: [Card]) -> HighlightColor {
        HighlightColorHelper.getHighlightColor(card.type == .spell, card.type == .minion)
    }
}
