//
//  BloodreaverGuldan.swift
//  HSTracker
//
//  Created by Francisco Moraes on 12/13/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class BloodreaverGuldan: ResurrectionCard {
    required init() {
        
    }
    
    override func getCardId() -> String {
        return CardIds.Collectible.Warlock.BloodreaverGuldan
    }

    override func filterCard(card: Card) -> Bool {
        return card.isDemon()
    }
    
    override func resurrectsMultipleCards() -> Bool {
        return true
    }
}
