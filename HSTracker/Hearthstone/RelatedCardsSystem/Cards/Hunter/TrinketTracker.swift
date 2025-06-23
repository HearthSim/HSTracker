//
//  TrinketTracker.swift
//  HSTracker
//
//  Created by Francisco Moraes on 6/20/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class TrinketTracker: ICardWithHighlight {
    required init() {}

    func getCardId() -> String {
        CardIds.Collectible.Hunter.TrinketTracker
    }

    func shouldHighlight(card: Card, deck: [Card]) -> HighlightColor {
        HighlightColorHelper.getHighlightColor(card.type == .spell && card.cost == 1)
    }
}
