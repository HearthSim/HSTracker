//
//  WayOfTheShellHeroic.swift
//  HSTracker
//
//  Created by Francisco Moraes on 7/7/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class WayOfTheShellHeroic: ICardWithHighlight {
    required init() {
        
    }
    
    func getCardId() -> String {
        return CardIds.NonCollectible.Rogue.WayOfTheShellHeroic
    }

    func shouldHighlight(card: Card, deck: [Card]) -> HighlightColor {
        return HighlightColorHelper.getHighlightColor(card.isCreated)
    }
}
