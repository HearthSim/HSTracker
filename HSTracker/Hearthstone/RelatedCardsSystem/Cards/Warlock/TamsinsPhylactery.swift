//
//  TamsinsPhylactery.swift
//  HSTracker
//
//  Created by Francisco Moraes on 12/13/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class TamsinsPhylactery: ResurrectionCard {
    required init() {
        
    }
    
    override func getCardId() -> String {
        return CardIds.Collectible.Warlock.TamsinsPhylactery
    }
    
    override func filterCard(card: Card) -> Bool {
        return card.hasDeathrattle()
    }
    
    override func resurrectsMultipleCards() -> Bool {
        return false
    }
}
