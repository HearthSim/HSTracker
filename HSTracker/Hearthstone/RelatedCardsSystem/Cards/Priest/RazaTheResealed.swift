//
//  RazaTheResealed.swift
//  HSTracker
//
//  Created by Francisco Moraes on 3/27/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class RazaTheResealed: ResurrectionCard {
    
    public required init() { }
    
    public override func getCardId() -> String {
        return CardIds.Collectible.Priest.RazaTheResealed
    }
    
    override func filterCard(card: Card) -> Bool {
        return true
    }
    
    override func resurrectsMultipleCards() -> Bool {
        return true
    }
}
