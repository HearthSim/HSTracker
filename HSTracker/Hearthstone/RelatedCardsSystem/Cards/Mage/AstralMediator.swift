//
//  AstralMediator.swift
//  HSTracker
//
//  Created by Francisco Moraes on 10/13/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

// "Battlecry and Deathrattle: Cast a random 3-Cost spell."
class AstralMediator: Cost3SpellPool {
    override func getCardId() -> String { CardIds.Collectible.Mage.AstralMediator }
    override func picks() -> Int { 1 }
    override func eventCount() -> Int { 2 }
    override func isWithReplacement() -> Bool { true }
}
