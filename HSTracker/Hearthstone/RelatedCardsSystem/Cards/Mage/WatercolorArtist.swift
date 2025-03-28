//
//  WatercolorArtist.swift
//  HSTracker
//
//  Created by Francisco Moraes on 3/24/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class WatercolorArtist: ICardWithHighlight {
    required init() {}
    
    func getCardId() -> String {
        return CardIds.Collectible.Mage.WatercolorArtist
    }
    
    func shouldHighlight(card: Card, deck: [Card]) -> HighlightColor {
        return HighlightColorHelper.getHighlightColor(
            card.spellSchool == SpellSchool.frost
        )
    }
}
