//
//  Reload.swift
//  HSTracker
//
//  Created by Francisco Moraes on 10/13/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

// "Discover a spell and reduce its Cost by (8). Repeat this with excess Cost reduction."
// eventCount stays 1: the repeats depend on the picked spells' costs.
class Reload: ClassOrNeutralSpellPool {
    override func getCardId() -> String { CardIds.Collectible.Hunter.Reload }
}
