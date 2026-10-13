//
//  UldirQuarantine.swift
//  HSTracker
//
//  Created by Francisco Moraes on 10/13/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

// "Locked until you play a card from each Rune. Summon a random 5-Cost minion."
class UldirQuarantine: Cost5MinionPool {
    override func getCardId() -> String { CardIds.Collectible.Deathknight.UldirQuarantine }
    override func picks() -> Int { 1 }
    override func isWithReplacement() -> Bool { true }
}
