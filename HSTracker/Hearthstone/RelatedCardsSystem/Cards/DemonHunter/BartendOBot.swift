//
//  BartendOBot.swift
//  HSTracker
//
//  Created by Francisco Moraes on 3/19/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class BartendOBot: ICardWithHighlight {
    required init() {
        
    }
    
    func getCardId() -> String {
        return CardIds.Collectible.DemonHunter.BartendOBot
    }

    func shouldHighlight(card: Card, deck: [Card]) -> HighlightColor {
        let hasOutcast = card.mechanics.contains("OUTCAST")
        return HighlightColorHelper.getHighlightColor(hasOutcast)
    }
}
