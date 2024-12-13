//
//  UnendingSwarm.swift
//  HSTracker
//
//  Created by Francisco Moraes on 12/13/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class UnendingSwarm: ResurrectionCard {
    required init() {
        
    }
    
    override func getCardId() -> String {
        return CardIds.Collectible.Druid.UnendingSwarm
    }
    
    override func filterCard(card: Card) -> Bool {
        return card.cost <= 2
    }
    
    override func resurrectsMultipleCards() -> Bool {
        return true
    }
}
