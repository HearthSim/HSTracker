//
//  OverlordSaurfang.swift
//  HSTracker
//
//  Created by Francisco Moraes on 5/22/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class OverlordSaurfang: ResurrectionCard {
    override func getCardId() -> String {
        CardIds.Collectible.Warrior.OverlordSaurfang
    }

    override func shouldShowForOpponent(opponent: Player) -> Bool {
        let game = AppDelegate.instance().coreManager.game
        guard let card = Cards.by(cardId: getCardId()) else { return false }
        return CardUtils.mayCardBeRelevant(card: card, gameType: game.currentGameType, format: game.currentFormatType, playerClass: opponent.originalClass) &&
               getRelatedCards(player: opponent).count > 0
    }

    override func filterCard(card: Card) -> Bool {
        card.mechanics.contains("FRENZY")
    }

    override func resurrectsMultipleCards() -> Bool {
        true
    }
}
