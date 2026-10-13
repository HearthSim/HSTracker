//
//  ScionOfInsight.swift
//  HSTracker
//
//  Created by Francisco Moraes on 10/13/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

// "Battlecry: Discover a Blood, Frost or Unholy card. Gain Lifesteal, Reborn or Rush based on your choice."
// The Discover offers one option per rune. Modelled as three single draws from the union of all rune
// cards - an approximation, since each option actually comes from its own rune's sub-pool.
class ScionOfInsight: RuneCardPool {
    override func getCardId() -> String { CardIds.Collectible.Deathknight.ScionOfInsight }
    override func picks() -> Int { 1 }
    override func eventCount() -> Int { 3 }
}
