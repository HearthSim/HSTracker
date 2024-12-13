//
//  Rally.swift
//  HSTracker
//
//  Created by Francisco Moraes on 12/13/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class Rally: ResurrectionCard {
    required init() {
        
    }
    
    override func getCardId() -> String {
        return CardIds.Collectible.Neutral.Rally
    }
    
    override func filterCard(card: Card) -> Bool {
        return card.attack >= 1 && card.attack <= 3
    }
    
    override func resurrectsMultipleCards() -> Bool {
        return true
    }
}
