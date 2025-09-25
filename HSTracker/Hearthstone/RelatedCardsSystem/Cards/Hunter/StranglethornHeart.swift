//
//  StranglethornHeart.swift
//  HSTracker
//
//  Created by Francisco Moraes on 11/7/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class StranglethornHeart: ResurrectionCard {
    
    override func getCardId() -> String {
        return CardIds.Collectible.Hunter.StranglethornHeart
    }

    override func filterCard(card: Card) -> Bool {
        return card.isBeast() && card.cost >= 5
    }

    override func resurrectsMultipleCards() -> Bool {
        return true
    }
    
    override func shouldShowForOpponent(opponent: Player) -> Bool {
        guard let card = Cards.by(cardId: getCardId()) else {
            return false
        }
        let game = AppDelegate.instance().coreManager.game
        return CardUtils.mayCardBeRelevant(card: card, gameType: game.currentGameType, format: game.currentFormatType, playerClass: opponent.originalClass) && getRelatedCards(player: opponent).count > 1
    }

    required init() {
    }
}
