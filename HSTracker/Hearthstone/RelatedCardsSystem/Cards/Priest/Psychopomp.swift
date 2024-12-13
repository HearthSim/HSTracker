//
//  Psychopomp.swift
//  HSTracker
//
//  Created by Francisco Moraes on 12/13/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class Psychopomp: ResurrectionCard {
    required init() {
        
    }
    
    override func getCardId() -> String {
        return CardIds.Collectible.Priest.Psychopomp
    }

    override func filterCard(card: Card) -> Bool {
        return true
    }
    
    override func resurrectsMultipleCards() -> Bool {
        return false
    }
}
