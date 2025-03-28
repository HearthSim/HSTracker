//
//  BlindeyeSharpshooter.swift
//  HSTracker
//
//  Created by Francisco Moraes on 3/19/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class BlindeyeSharpshooter: ICardWithHighlight {
    required init() {
        
    }
    
    func getCardId() -> String {
        return CardIds.Collectible.DemonHunter.BlindeyeSharpshooter
    }

    func shouldHighlight(card: Card, deck: [Card]) -> HighlightColor {
        let isNaga = card.isNaga()
        let isSpell = card.type == CardType.spell
        return HighlightColorHelper.getHighlightColor(isNaga, isSpell)
    }
}
