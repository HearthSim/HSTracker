//
//  Tyr.swift
//  HSTracker
//
//  Created by Francisco Moraes on 11/7/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class Tyr: ICardWithRelatedCards {
    
    func getCardId() -> String {
        return CardIds.Collectible.Paladin.Tyr
    }

    func shouldShowForOpponent(opponent: Player) -> Bool {
        guard let card = Cards.by(cardId: getCardId()) else {
            return false
        }
        return CardUtils.mayCardBeRelevant(card: card, format: AppDelegate.instance().coreManager.game.currentFormat, playerClass: opponent.playerClass) && getRelatedCards(player: opponent).count > 0
    }

    func getRelatedCards(player: Player) -> [Card?] {
        return player.deadMinionsCardIds
            .unique()
            .compactMap { Cards.by(cardId: $0) }
            .filter { $0.isClass(cardClass: player.playerClass ?? .invalid) && $0.attack > 1 && $0.attack < 5 }
            .sorted { $0.cost < $1.cost }
    }

    required init() {
    }
}
