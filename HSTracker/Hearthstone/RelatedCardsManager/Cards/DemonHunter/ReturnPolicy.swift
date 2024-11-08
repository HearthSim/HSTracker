//
//  ReturnPolicy.swift
//  HSTracker
//
//  Created by Francisco Moraes on 11/5/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class ReturnPolicy: ICardWithRelatedCards {
    
    func getCardId() -> String {
        return CardIds.Collectible.DemonHunter.ReturnPolicy
    }

    func shouldShowForOpponent(opponent: Player) -> Bool {
        guard let card = Cards.by(cardId: getCardId()) else {
            return false
        }
        return CardUtils.mayCardBeRelevant(card: card, format: AppDelegate.instance().coreManager.game.currentFormat, playerClass: opponent.playerClass) && getRelatedCards(player: opponent).count > 1
    }
    
    func getRelatedCards(player: Player) -> [Card?] {
        return player
            .cardsPlayedThisTurn
            .compactMap { CardUtils.getProcessedCardFromCardId($0.cardId, player) }
            .unique()
            .filter { $0.mechanics.firstIndex(of: "DEATHRATTLE") != nil }
            .sorted(by: { $0.cost > $1.cost })
    }

    required init() {
    }
}
