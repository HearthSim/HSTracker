//
//  JimRaynor.swift
//  HSTracker
//
//  Created by Francisco Moraes on 1/22/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class JimRaynor: ICardWithRelatedCards {
    required init() {
        // Required initializer
    }

    func getCardId() -> String {
        return CardIds.Collectible.Invalid.JimRaynor
    }

    func shouldShowForOpponent(opponent: Player) -> Bool {
        guard let card = Cards.by(cardId: getCardId()) else { return false }
        return CardUtils.mayCardBeRelevant(card: card, format: AppDelegate.instance().coreManager.game.currentFormat, playerClass: opponent.originalClass) && !getRelatedCards(player: opponent).isEmpty
    }

    func getRelatedCards(player: Player) -> [Card?] {
        return player.launchedStarships.compactMap { Cards.any(byId: $0 ?? "") }
    }
}
