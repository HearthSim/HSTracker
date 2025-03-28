//
//  FalricCorePlaceholder.swift
//  HSTracker
//
//  Created by Francisco Moraes on 3/27/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class FalricCorePlaceholder: ICardWithHighlight {
    required init() {
        
    }
    
    func getCardId() -> String {
        return CardIds.Collectible.Deathknight.FalricCore
    }

    func shouldHighlight(card: Card, deck: [Card]) -> HighlightColor {
        return HighlightColorHelper.getHighlightColor(card.tag4058 > 0)
    }
}
