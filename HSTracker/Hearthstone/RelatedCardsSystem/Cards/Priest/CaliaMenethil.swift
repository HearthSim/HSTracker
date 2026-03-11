//
//  CaliaMenethil.swift
//  HSTracker
//
//  Created by Francisco Moraes on 3/11/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

class CaliaMenethil: ICardWithRelatedCards {

    required init() {}

    func getCardId() -> String {
        return CardIds.Collectible.Priest.CaliaMenethilCorePlaceholder
    }

    func shouldShowForOpponent(opponent: Player) -> Bool {
        return false
    }

    func getRelatedCards(player: Player) -> [Card?] {
        let playerMinions = player.deadMinionsCards.compactMap { entity in
            CardUtils.getProcessedCardFromEntity(entity, player)
        }

        guard let highestCost = playerMinions.map({ $0.cost }).max() else {
            return []
        }

        return playerMinions.filter { $0.cost == highestCost }
    }
}
