//
//  Blink.swift
//  HSTracker
//
//  Created by Francisco Moraes on 3/24/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class Blink: ICardWithHighlight {
    required init() {}
    
    func getCardId() -> String {
        return CardIds.Collectible.Rogue.Blink
    }
    
    func shouldHighlight(card: Card, deck: [Card]) -> HighlightColor {
        return HighlightColorHelper.getHighlightColor(card.type == .minion && card.faction == .protoss)
    }
}
