//
//  Fetch.swift
//  HSTracker
//
//  Created by Francisco Moraes on 3/21/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class Fetch: ICardWithHighlight {
    required init() {}
    
    func getCardId() -> String {
        return CardIds.Collectible.Hunter.Fetch
    }
    
    func shouldHighlight(card: Card) -> HighlightColor {
        return HighlightColorHelper.getHighlightColor(
            card.isBeast(),
            card.type == .minion,
            card.type == .spell
        )
    }
}
