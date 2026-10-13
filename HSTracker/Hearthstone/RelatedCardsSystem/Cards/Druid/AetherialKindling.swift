//
//  AetherialKindling.swift
//  HSTracker
//
//  Created by Francisco Moraes on 10/13/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

// "Deal 3 damage. Summon a random 3-Cost minion."
class AetherialKindling: Cost3MinionPool {
    override func getCardId() -> String { CardIds.Collectible.Druid.AetherialKindling }
    override func picks() -> Int { 1 }
    override func isWithReplacement() -> Bool { true }
}
