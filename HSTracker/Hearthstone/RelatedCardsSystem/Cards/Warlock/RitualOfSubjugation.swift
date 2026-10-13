//
//  RitualOfSubjugation.swift
//  HSTracker
//
//  Created by Francisco Moraes on 10/13/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

// "In 2 turns, summon three random Legendary minions. Get a 1-Cost copy of each."
// Kith'ix's Ritual.
class RitualOfSubjugation: LegendaryMinionPool {
    override func getCardId() -> String { CardIds.NonCollectible.Warlock.Kithix_RitualOfSubjugationToken }
    override func picks() -> Int { 1 }
    override func eventCount() -> Int { 3 }
    override func isWithReplacement() -> Bool { true }
}
