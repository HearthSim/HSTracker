//
//  Archaedas.swift
//  HSTracker
//
//  Created by Francisco Moraes on 10/13/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

// "Battlecry: Discover a spell. Transform it into a 3/3 weapon of the same cost that casts it each attack."
class Archaedas: ClassOrNeutralSpellPool {
    override func getCardId() -> String { CardIds.Collectible.Warrior.Archaedas }
}
