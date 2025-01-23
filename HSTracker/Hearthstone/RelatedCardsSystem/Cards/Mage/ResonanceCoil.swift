//
//  ResonanceCoil.swift
//  HSTracker
//
//  Created by Francisco Moraes on 1/22/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class ResonanceCoil: ICardWithRelatedCards {
    required init() {
        
    }
    
    private var cache: [Card?]?

    func getCardId() -> String {
        return CardIds.Collectible.Mage.ResonanceCoil
    }

    func shouldShowForOpponent(opponent: Player) -> Bool {
        return false
    }

    func getRelatedCards(player: Player) -> [Card?] {
        if let cached = cache {
            return cached
        }

        let cardId = getCardId()

        cache = Cards.collectible()
            .filter { card in
                card.faction == .protoss &&
                card.type == .spell &&
                card.id != cardId
            }
            .compactMap { $0.copy() }
            .sorted { $0.cost < $1.cost }

        return cache ?? []
    }
}
