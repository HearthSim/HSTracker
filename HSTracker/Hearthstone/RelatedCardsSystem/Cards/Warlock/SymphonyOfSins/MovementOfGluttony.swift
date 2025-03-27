//
//  MovementOfGluttony.swift
//  HSTracker
//
//  Created by Francisco Moraes on 3/24/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class MovementOfGluttony: ICardWithHighlight {
    required init() {}
    
    func getCardId() -> String {
        return CardIds.NonCollectible.Warlock.SymphonyofSins_MovementOfGluttonyToken
    }
    
    func shouldHighlight(card: Card) -> HighlightColor {
        return HighlightColorHelper.getHighlightColor(card.type == .minion)
    }
}
