//
//  UrsineMaul.swift
//  HSTracker
//
//  Created by Francisco Moraes on 3/27/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

public class UrsineMaul: ICardWithHighlight {
    
    public required init() { }
    
    public func getCardId() -> String {
        return CardIds.Collectible.Paladin.UrsineMaul
    }
    
    func shouldHighlight(card: Card, deck: [Card]) -> HighlightColor {
        let highestCost = deck.max { $0.cost < $1.cost }?.cost ?? 0
        return HighlightColorHelper.getHighlightColor(card.cost == highestCost)
    }
}
