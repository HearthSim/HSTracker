//
//  TombLurker.swift
//  HSTracker
//
//  Created by Francisco Moraes on 12/13/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class TombLurker: ResurrectionCard {
    required init() {
        
    }
    
    override func getCardId() -> String {
        return CardIds.Collectible.Neutral.TombLurker
    }
    
    override func filterCard(card: Card) -> Bool {
        return card.hasDeathrattle()
    }
    
    override func resurrectsMultipleCards() -> Bool {
        return false
    }
}