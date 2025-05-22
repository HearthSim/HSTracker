//
//  PrimordialProtector.swift
//  HSTracker
//
//  Created by Francisco Moraes on 5/22/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class PrimordialProtector: ICardWithHighlight {
    required init() {}
    
    func getCardId() -> String {
        return CardIds.Collectible.Neutral.PrimordialProtector
    }
    
    func shouldHighlight(card: Card, deck: [Card]) -> HighlightColor {
        let spells = deck.filter { $0.type == .spell }
        guard !spells.isEmpty else {
            return .none
        }
        let highestCost = spells.max(by: { $0.cost < $1.cost })?.cost ?? 0
        return HighlightColorHelper.getHighlightColor(
            card.type == .spell && card.cost == highestCost
        )
    }
}
