//
//  TrinketArtist.swift
//  HSTracker
//
//  Created by Francisco Moraes on 3/24/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class TrinketArtist: ICardWithHighlight {
    required init() {}
    
    func getCardId() -> String {
        return CardIds.Collectible.Paladin.TrinketArtist
    }
    
    func shouldHighlight(card: Card, deck: [Card]) -> HighlightColor {
        return HighlightColorHelper.getHighlightColor(
            card.mechanics.contains("PALADIN_AURA"),
            card.mechanics.contains("DIVINE_SHIELD")
        )
    }
}
