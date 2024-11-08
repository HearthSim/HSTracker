//
//  LadyLiadrinCore.swift
//  HSTracker
//
//  Created by Francisco Moraes on 11/7/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class LadyLiadrinCore: ICardWithRelatedCards {
    
    func getCardId() -> String {
        return CardIds.Collectible.Paladin.LadyLiadrinCore
    }

    func shouldShowForOpponent(opponent: Player) -> Bool {
        guard let card = Cards.by(cardId: getCardId()) else {
            return false
        }
        return CardUtils.mayCardBeRelevant(card: card, format: AppDelegate.instance().coreManager.game.currentFormat, playerClass: opponent.playerClass) && getRelatedCards(player: opponent).count > 2
    }

    func getRelatedCards(player: Player) -> [Card?] {
        return player.spellsPlayedInFriendlyCharacters
            .compactMap { CardUtils.getProcessedCardFromCardId($0.cardId, player) }
    }

    required init() {
    }
}
