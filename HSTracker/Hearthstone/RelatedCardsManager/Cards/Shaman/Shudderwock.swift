//
//  Shudderwock.swift
//  HSTracker
//
//  Created by Francisco Moraes on 11/7/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class Shudderwock: ICardWithRelatedCards {
    
    func getCardId() -> String {
        return CardIds.Collectible.Shaman.Shudderwock
    }

    func shouldShowForOpponent(opponent: Player) -> Bool {
        guard let card = Cards.by(cardId: getCardId()) else {
            return false
        }
        return CardUtils.mayCardBeRelevant(card: card, format: AppDelegate.instance().coreManager.game.currentFormat, playerClass: opponent.playerClass) && getRelatedCards(player: opponent).count > 3
    }

    func getRelatedCards(player: Player) -> [Card?] {
        return player.cardsPlayedThisMatch
            .compactMap { Cards.by(cardId: $0) }
            .filter { $0.mechanics.contains("Battlecry") == true }
    }

    required init() {
    }
}
