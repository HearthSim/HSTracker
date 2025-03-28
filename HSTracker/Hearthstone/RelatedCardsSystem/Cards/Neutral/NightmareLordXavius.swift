//
//  NightmareLordXavius.swift
//  HSTracker
//
//  Created by Francisco Moraes on 3/27/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

public class NightmareLordXavius: ICardWithHighlight {
    
    public required init() {
    }
    
    public func getCardId() -> String {
        return CardIds.Collectible.Neutral.NightmareLordXavius
    }
    
    func shouldHighlight(card: Card, deck: [Card]) -> HighlightColor {
        return HighlightColorHelper.getHighlightColor(card.type == .minion)
    }
}
