//
//  WakenerOfSouls.swift
//  HSTracker
//
//  Created by Francisco Moraes on 11/8/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class WakenerOfSouls: ICardWithRelatedCards {
    
    func getCardId() -> String {
        return CardIds.Collectible.Deathknight.WakenerOfSouls
    }

    func shouldShowForOpponent(opponent: Player) -> Bool {
        return false
    }

    func getRelatedCards(player: Player) -> [Card?] {
        return player.deadMinionsCards
            .compactMap { CardUtils.getProcessedCardFromCardId($0.cardId, player) }
            .unique()
            .filter { $0.mechanics.contains("DEATHRATTLE") == true && $0.id != CardIds.Collectible.Deathknight.WakenerOfSouls }
            .sorted(by: { $0.cost > $1.cost })
    }

    required init() {
    }
}
