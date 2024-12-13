//
//  InventorBoom.swift
//  HSTracker
//
//  Created by Francisco Moraes on 11/7/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class InventorBoom: ResurrectionCard {
    
    override func getCardId() -> String {
        return CardIds.Collectible.Warrior.InventorBoom
    }

    override func shouldShowForOpponent(opponent: Player) -> Bool {
        guard let card = Cards.by(cardId: getCardId()) else {
            return false
        }
        return CardUtils.mayCardBeRelevant(card: card, format: AppDelegate.instance().coreManager.game.currentFormat, playerClass: opponent.originalClass) && getRelatedCards(player: opponent).count > 0
    }

    override func filterCard(card: Card) -> Bool {
        return card.isMech() && card.cost >= 5
    }
    
    override func resurrectsMultipleCards() -> Bool {
        return true
    }

    required init() { }
}
