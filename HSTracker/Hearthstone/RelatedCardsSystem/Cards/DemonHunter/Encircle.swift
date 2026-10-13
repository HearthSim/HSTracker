//
//  Encircle.swift
//  HSTracker
//
//  Created by Francisco Moraes on 10/13/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

// "Summon five 3/1 Shredclaws with Rush. Summon a random 1-Cost minion for your opponent."
class Encircle: Cost1MinionPool {
    override func getCardId() -> String { CardIds.Collectible.DemonHunter.Encircle }
    override func picks() -> Int { 1 }
    override func isWithReplacement() -> Bool { true }
}
