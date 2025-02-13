//
//  Bonecaller.swift
//  HSTracker
//
//  Created by Francisco Moraes on 12/13/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class Bonecaller: ResurrectionCard {
    required init() {
        
    }
    
    override func getCardId() -> String {
        return CardIds.Collectible.Priest.Bonecaller
    }

    override func filterCard(card: Card) -> Bool {
        return card.isUndead()
    }

    override func resurrectsMultipleCards() -> Bool {
        return false
    }
}
