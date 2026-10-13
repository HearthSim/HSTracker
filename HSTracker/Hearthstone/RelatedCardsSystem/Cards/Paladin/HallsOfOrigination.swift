//
//  HallsOfOrigination.swift
//  HSTracker
//
//  Created by Francisco Moraes on 10/13/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

// "Lifesteal. Deal 8 damage randomly split among all enemies. Summon an 8-Cost minion."
class HallsOfOrigination: Cost8MinionPool {
    override func getCardId() -> String { CardIds.Collectible.Paladin.HallsOfOrigination }
    override func picks() -> Int { 1 }
    override func isWithReplacement() -> Bool { true }
}
