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
    
    func shouldHighlight(card: Card) -> HighlightColor {
        return HighlightColorHelper.getHighlightColor(card.type == .minion)
    }
}
