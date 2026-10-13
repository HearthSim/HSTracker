//
//  SpawnOfYshaarj.swift
//  HSTracker
//
//  Created by Francisco Moraes on 10/13/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

// "Summon a random minion that costs (8) or more. Get a copy of it."
// Y'Shaarj, Titan Bane's ability.
class SpawnOfYshaarj: CostAtLeast8MinionPool {
    override func getCardId() -> String { CardIds.NonCollectible.Neutral.YShaarjTitanBane_SpawnOfYshaarjToken }
    override func picks() -> Int { 1 }
    override func isWithReplacement() -> Bool { true }
}
