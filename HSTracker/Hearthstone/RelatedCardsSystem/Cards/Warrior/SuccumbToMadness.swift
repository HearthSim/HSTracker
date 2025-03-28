//
//  SuccumbToMadness.swift
//  HSTracker
//
//  Created by Francisco Moraes on 3/27/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class SuccumbToMadness: ResurrectionCard {
    
    public required init() { }
    
    public override func getCardId() -> String {
        return CardIds.Collectible.Warrior.SuccumbToMadness
    }
    
    public override func shouldShowForOpponent(opponent: Player) -> Bool {
        guard let card = Cards.by(cardId: getCardId()) else {
            return false
        }
        return CardUtils.mayCardBeRelevant(card: card, format: AppDelegate.instance().coreManager.game.currentFormat, playerClass: opponent.originalClass) && getRelatedCards(player: opponent).count > 0
    }
    
    override func filterCard(card: Card) -> Bool {
        return card.isDragon()
    }
    
    override func resurrectsMultipleCards() -> Bool {
        return false
    }
}
