//
//  DeathSpeakerBlackthorn.swift
//  HSTracker
//
//  Created by Francisco Moraes on 5/21/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class DeathSpeakerBlackthorn: ICardWithHighlight {
    required init() {
        
    }
    
    func getCardId() -> String {
        return CardIds.Collectible.DemonHunter.DeathSpeakerBlackthorn
    }

    func shouldHighlight(card: Card, deck: [Card]) -> HighlightColor {
        return HighlightColorHelper.getHighlightColor(card.hasDeathrattle() && card.cost <= 5)
    }
}
