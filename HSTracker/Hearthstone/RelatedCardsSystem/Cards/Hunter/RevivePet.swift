//
//  RevivePet.swift
//  HSTracker
//
//  Created by Francisco Moraes on 12/13/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class RevivePet: ResurrectionCard {
    required init() {
        
    }
    
    override func getCardId() -> String {
        return CardIds.Collectible.Hunter.RevivePet
    }

    override func filterCard(card: Card) -> Bool {
        return card.isBeast()
    }

    override func resurrectsMultipleCards() -> Bool {
        return false
    }
}
