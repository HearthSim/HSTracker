//
//  BlindHarrower.swift
//  HSTracker
//
//  Created by Francisco Moraes on 10/13/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

// "Outcast and Deathrattle: Get a random Outcast card."
// eventCount stays 1: the Outcast trigger is conditional.
class BlindHarrower: OutcastCardPool {
    override func getCardId() -> String { CardIds.Collectible.DemonHunter.BlindHarrower }
    override func picks() -> Int { 1 }
    override func isWithReplacement() -> Bool { true }
}
