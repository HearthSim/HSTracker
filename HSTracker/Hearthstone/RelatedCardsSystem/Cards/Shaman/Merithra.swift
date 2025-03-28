//
//  Merithra.swift
//  HSTracker
//
//  Created by Francisco Moraes on 3/27/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class Merithra: ResurrectionCard {
    
    public required init() { }
    
    public override func getCardId() -> String {
        return CardIds.Collectible.Shaman.Merithra
    }
    
    override func filterCard(card: Card) -> Bool {
        return card.cost >= 8
    }
    
    override func resurrectsMultipleCards() -> Bool {
        return false
    }
}
