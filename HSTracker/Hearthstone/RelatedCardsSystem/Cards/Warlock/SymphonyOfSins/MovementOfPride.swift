//
//  MovementOfPride.swift
//  HSTracker
//
//  Created by Francisco Moraes on 3/24/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class MovementOfPride: ICardWithHighlight {
    required init() {}
    
    func getCardId() -> String {
        return CardIds.NonCollectible.Warlock.SymphonyofSins_MovementOfPrideToken
    }
    
    func shouldHighlight(card: Card, deck: [Card]) -> HighlightColor {
        let highestCost = deck.filter { $0.type == .minion }.max { $0.cost < $1.cost }?.cost ?? 0
        return HighlightColorHelper.getHighlightColor(
            card.type == .minion && card.cost == highestCost
        )
    }
}
