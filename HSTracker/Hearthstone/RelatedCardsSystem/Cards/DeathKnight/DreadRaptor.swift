//
//  DreadRaptor.swift
//  HSTracker
//
//  Created by Francisco Moraes on 7/2/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class DreadRaptor: ICardWithHighlight {
    required init() {}

    func getCardId() -> String {
        CardIds.Collectible.Deathknight.DreadRaptor
    }

    func shouldHighlight(card: Card, deck: [Card]) -> HighlightColor {
        HighlightColorHelper.getHighlightColor(
            card.hasDeathrattle() && card.cost < 3 && card.type == .minion
        )
    }
}
