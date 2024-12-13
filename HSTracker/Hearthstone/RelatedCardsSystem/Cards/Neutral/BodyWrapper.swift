//
//  BodyWrapper.swift
//  HSTracker
//
//  Created by Francisco Moraes on 12/13/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class BodyWrapper: ResurrectionCard {
    required init() {
        
    }
    
    override func getCardId() -> String {
        return CardIds.Collectible.Neutral.BodyWrapper
    }

    override func filterCard(card: Card) -> Bool {
        return true
    }

    override func resurrectsMultipleCards() -> Bool {
        return false
    }
}
