//
//  Mothership.swift
//  HSTracker
//
//  Created by Francisco Moraes on 1/22/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class Mothership: ICardWithRelatedCards {
    private var cache: [Card?]?

    required init() {}

    func getCardId() -> String {
        return CardIds.Collectible.Priest.Mothership
    }

    func shouldShowForOpponent(opponent: Player) -> Bool {
        return false
    }

    func getRelatedCards(player: Player) -> [Card?] {
        if let cache = cache {
            return cache
        }

        let cardId = getCardId()

        cache = Cards.collectible()
            .filter { $0.faction == .protoss && $0.type == .minion && $0.id != cardId }
            .compactMap { $0.copy() }
            .sorted { $0.cost < $1.cost }

        return cache ?? []
    }
}
