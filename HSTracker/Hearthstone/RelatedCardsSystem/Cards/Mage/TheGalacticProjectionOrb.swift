//
//  TheGalacticProjectionOrb.swift
//  HSTracker
//
//  Created by Francisco Moraes on 11/7/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class TheGalacticProjectionOrb: ICardWithRelatedCards {
    
    func getCardId() -> String {
        return CardIds.Collectible.Mage.TheGalacticProjectionOrb
    }

    func shouldShowForOpponent(opponent: Player) -> Bool {
        guard let card = Cards.by(cardId: getCardId()) else {
            return false
        }
        let game = AppDelegate.instance().coreManager.game
        return CardUtils.mayCardBeRelevant(card: card, gameType: game.currentGameType, format: game.currentFormatType, playerClass: opponent.originalClass) && getRelatedCards(player: opponent).count > 1
    }

    func getRelatedCards(player: Player) -> [Card?] {
        return player.spellsPlayedCards
            .compactMap { CardUtils.getProcessedCardFromEntity($0, player) }
            .unique()
            .sorted { $0.cost < $1.cost }
    }

    required init() {
    }
}
