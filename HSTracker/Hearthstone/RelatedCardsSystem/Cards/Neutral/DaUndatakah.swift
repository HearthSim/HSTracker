//
//  DaUndatakah.swift
//  HSTracker
//
//  Created by Francisco Moraes on 12/13/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class DaUndatakah: ResurrectionCard {
    required init() {
    }
    
    override func getCardId() -> String {
        return CardIds.Collectible.Neutral.DaUndatakah
    }
    
    override func filterCard(card: Card) -> Bool {
        return card.hasDeathrattle()
    }
    
    override func resurrectsMultipleCards() -> Bool {
        return true
    }
}
