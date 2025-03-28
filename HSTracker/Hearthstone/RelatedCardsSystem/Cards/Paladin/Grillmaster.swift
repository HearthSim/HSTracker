//
//  Grillmaster.swift
//  HSTracker
//
//  Created by Francisco Moraes on 3/27/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

//swiftlint:disable inclusive_language
public class Grillmaster: ICardWithHighlight {
    
    public required init() { }
    
    public func getCardId() -> String {
        return CardIds.Collectible.Paladin.Grillmaster
    }
    
    func shouldHighlight(card: Card, deck: [Card]) -> HighlightColor {
        let lowestCost = deck.min { $0.cost < $1.cost }?.cost ?? 0
        let highestCost = deck.max { $0.cost < $1.cost }?.cost ?? 0
        return HighlightColorHelper.getHighlightColor(
            card.cost == highestCost,
            card.cost == lowestCost
        )
    }
}
//swiftlint:enable inclusive_language
