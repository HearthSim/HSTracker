//
//  Product9.swift
//  HSTracker
//
//  Created by Francisco Moraes on 11/7/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class Product9: ICardWithRelatedCards {
    
    func getCardId() -> String {
        return CardIds.Collectible.Hunter.Product9
    }

    func shouldShowForOpponent(opponent: Player) -> Bool {
        guard let card = Cards.by(cardId: getCardId()) else {
            return false
        }
        return CardUtils.mayCardBeRelevant(card: card, format: AppDelegate.instance().coreManager.game.currentFormat, playerClass: opponent.playerClass) && getRelatedCards(player: opponent).count > 0
    }

    func getRelatedCards(player: Player) -> [Card?] {
        return player.secretsTriggeredCardIds
            .unique()
            .compactMap { Cards.by(cardId: $0) }
            .sorted { $0.cost > $1.cost }
    }

    required init() {
    }
}
