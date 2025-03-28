//
//  ScaleReplica.swift
//  HSTracker
//
//  Created by Francisco Moraes on 3/24/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

public class ScaleReplica: ICardWithHighlight {
    
    public required init() { }
    
    public func getCardId() -> String {
        return CardIds.Collectible.Priest.ScaleReplica
    }
    
    // TODO: use deck state to get highest and lowest cost
    func shouldHighlight(card: Card, deck: [Card]) -> HighlightColor {
        let dragons = deck.filter { $0.isDragon() }
        let lowestCost = dragons.min { $0.cost < $1.cost }?.cost ?? 0
        let highestCost = dragons.max { $0.cost < $1.cost }?.cost ?? 0
        return HighlightColorHelper.getHighlightColor(
            card.isDragon() && card.cost == highestCost,
            card.isDragon() && card.cost == lowestCost
        )
    }
}
