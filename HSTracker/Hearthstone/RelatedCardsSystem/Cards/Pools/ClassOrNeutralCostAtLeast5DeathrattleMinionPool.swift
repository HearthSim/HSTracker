//
//  ClassOrNeutralCostAtLeast5DeathrattleMinionPool.swift
//  HSTracker
//
//  Created by Francisco Moraes on 10/13/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

// Shared pool. Cards inherit this for the card pool only; each card declares its own
// picks()/eventCount()/isWithReplacement().
class ClassOrNeutralCostAtLeast5DeathrattleMinionPool: DiscoverPoolCard {
    override func getCardPool(playerClass: CardClass?, gt: GameType, format: FormatType) -> [Card] {
        return Cards.collectible().filter { $0.type == .minion && $0.cost >= 5 && $0.hasDeathrattle() && $0.isClassOrNeutral(playerClass) }
    }
}
