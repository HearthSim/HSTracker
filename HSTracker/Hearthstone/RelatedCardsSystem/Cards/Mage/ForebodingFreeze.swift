//
//  ForebodingFreeze.swift
//  HSTracker
//
//  Created by Francisco Moraes on 10/13/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

// "Freeze an enemy. Summon a random 5-Cost minion and Freeze it."
class ForebodingFreeze: Cost5MinionPool {
    override func getCardId() -> String { CardIds.Collectible.Mage.ForebodingFreeze }
    override func picks() -> Int { 1 }
    override func isWithReplacement() -> Bool { true }
}
