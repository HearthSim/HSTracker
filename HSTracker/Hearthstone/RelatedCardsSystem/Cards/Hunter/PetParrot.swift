//
//  PetParrot.swift
//  HSTracker
//
//  Created by Francisco Moraes on 11/7/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class PetParrot: ICardWithRelatedCards {
    
    func getCardId() -> String {
        return CardIds.Collectible.Hunter.PetParrot
    }

    func shouldShowForOpponent(opponent: Player) -> Bool {
        return false
    }

    func getRelatedCards(player: Player) -> [Card?] {
        let lastCost1 = player.cardsPlayedThisMatch
            .compactMap { CardUtils.getProcessedCardFromEntity($0, player) }
            .last(where: { $0.cost == 1 })
        
        return lastCost1 != nil ? [lastCost1] : []
    }

    required init() {
    }
}
