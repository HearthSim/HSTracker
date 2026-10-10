//
//  InfestTheScullery.swift
//  HSTracker
//
//  Created by Francisco Moraes on 8/26/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

// "Summon two random 2-Cost minions. (Improved by your hero attacks this game.)"
class InfestTheScullery: StateValuePoolCard {
    override func getCardId() -> String { CardIds.Collectible.Druid.InfestTheScullery }
    override var batchSize: Int { 2 }

    override func targetCost(player: Player, hoveredEntity: Entity?) -> Int? {
        let counter: InfestTheSculleryCounter? = RelativeCostPoolCard.getCounter(player: player)
        return counter?.summonCost ?? 2
    }
}
