//
//  ConfrontTheTolvir.swift
//  HSTracker
//
//  Created by Francisco Moraes on 3/11/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

class ConfrontTheTolvir: ICardWithRelatedCards {

    required init() {}

    func getCardId() -> String {
        return CardIds.Collectible.Hunter.ConfrontTheTolvir
    }

    func shouldShowForOpponent(opponent: Player) -> Bool {
        return false
    }

    func getRelatedCards(player: Player) -> [Card?] {
        return player.cardsPlayedThisMatch
            .compactMap { entity in CardUtils.getProcessedCardFromEntity(entity, player) }
            .filter { $0.cost == 1 }
    }
}
