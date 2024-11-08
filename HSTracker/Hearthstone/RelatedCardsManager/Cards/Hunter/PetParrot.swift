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
        guard let card = Cards.by(cardId: getCardId()) else {
            return false
        }
        return CardUtils.mayCardBeRelevant(card: card, format: AppDelegate.instance().coreManager.game.currentFormat, playerClass: opponent.playerClass) && getRelatedCards(player: opponent).count > 0
    }

    func getRelatedCards(player: Player) -> [Card?] {
        let lastCost1 = player.cardsPlayedThisMatch
            .compactMap { CardUtils.getProcessedCardFromCardId($0.cardId, player) }
            .last(where: { $0.cost == 1 })
        
        return lastCost1 != nil ? [lastCost1] : []
    }

    required init() {
    }
}
