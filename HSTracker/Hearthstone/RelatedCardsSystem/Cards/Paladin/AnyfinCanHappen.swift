//
//  AnyfinCanHappen.swift
//  HSTracker
//
//  Created by Francisco Moraes on 12/13/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class AnyfinCanHappen: ResurrectionCard {
    required init() {
        
    }
    
    override func getCardId() -> String {
        return CardIds.Collectible.Paladin.AnyfinCanHappen
    }

    override func filterCard(card: Card) -> Bool {
        return card.isMurloc()
    }

    override func resurrectsMultipleCards() -> Bool {
        return true
    }
}
