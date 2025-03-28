//
//  TaelanFordringCore.swift
//  HSTracker
//
//  Created by Francisco Moraes on 3/27/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

public class TaelanFordringCore: ICardWithHighlight {
    
    public required init() { }
    
    public func getCardId() -> String {
        return CardIds.Collectible.Neutral.TaelanFordringCore
    }
    
    func shouldHighlight(card: Card, deck: [Card]) -> HighlightColor {
        let minions = deck.filter { $0.type == .minion }
        let highestCost = minions.max { $0.cost < $1.cost }?.cost ?? 0
        return HighlightColorHelper.getHighlightColor(
            card.type == .minion && card.cost == highestCost
        )
    }
}
