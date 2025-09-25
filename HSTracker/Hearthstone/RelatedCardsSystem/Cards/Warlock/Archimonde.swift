//
//  Archimonde.swift
//  HSTracker
//
//  Created by Francisco Moraes on 11/8/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class Archimonde: ICardWithRelatedCards {
    
    func getCardId() -> String {
        return CardIds.Collectible.Warlock.Archimonde
    }

    func shouldShowForOpponent(opponent: Player) -> Bool {
        if let card = Cards.by(cardId: getCardId()) {
            let game = AppDelegate.instance().coreManager.game
            return CardUtils.mayCardBeRelevant(card: card, gameType: game.currentGameType, format: game.currentFormatType, playerClass: opponent.originalClass) && getRelatedCards(player: opponent).count > 1
        }
        return false
    }

    func getRelatedCards(player: Player) -> [Card?] {
        return player.cardsPlayedThisMatch
            .filter { $0.info.created }
            .compactMap { CardUtils.getProcessedCardFromEntity($0, player) }
            .filter { card in
                card.isDemon()
            }
            .sorted(by: {
                $0.cost > $1.cost
            })
    }

    required init() {
    }
}
