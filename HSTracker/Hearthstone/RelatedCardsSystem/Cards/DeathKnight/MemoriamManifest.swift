//
//  MemoriamManifest.swift
//  HSTracker
//
//  Created by Francisco Moraes on 11/4/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

class MemoriamManifest: ICardWithRelatedCards {
    func getCardId() -> String {
        CardIds.Collectible.Deathknight.MemoriamManifest
    }

    func shouldShowForOpponent(opponent: Player) -> Bool {
        false
    }

    func getRelatedCards(player: Player) -> [Card?] {
        let undeadsThatDied = player.deadMinionsCards
            .compactMap { entity in CardUtils.getProcessedCardFromEntity(entity, player) }
            .filter { $0?.isUndead() == true }

        guard !undeadsThatDied.isEmpty else {
            return []
        }

        let highestCost = undeadsThatDied.compactMap { $0?.cost }.max()
        return undeadsThatDied.filter { $0?.cost == highestCost }
    }

    required init() {}
}
