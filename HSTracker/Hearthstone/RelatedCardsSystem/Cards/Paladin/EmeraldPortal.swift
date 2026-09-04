//
//  EmeraldPortal.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/4/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

// "Casts When Drawn Summon a random 1-Cost Dragon."
// The printed "1-Cost" is a placeholder: the token shuffled in by Blessing of the Dragon
// summons Dragons costing as much as the number of times the player has Imbued, so the
// bucket is read from the Imbue counter (1 when no counter is running yet).
class EmeraldPortal: StateValuePoolCard {
    override func getCardId() -> String { CardIds.NonCollectible.Paladin.EmeraldPortal }
    override func isInPool(_ card: Card) -> Bool { card.type == .minion && card.isDragon() }
    override var poolCacheKey: String { "dragons" }

    override func targetCost(player: Player, hoveredEntity: Entity?) -> Int? {
        let counter: ImbueCounter? = RelativeCostPoolCard.getCounter(player: player)
        return counter?.counter ?? 1
    }
}
