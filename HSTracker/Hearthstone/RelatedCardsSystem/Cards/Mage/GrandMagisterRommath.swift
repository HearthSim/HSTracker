//
//  GrandMagisterRommath.swift
//  HSTracker
//
//  Created by Francisco Moraes on 12/13/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class GrandMagisterRommath: ICardWithRelatedCards {
    
    required init() {
        
    }
    
    func getCardId() -> String {
        return CardIds.Collectible.Mage.GrandMagisterRommath
    }

    func shouldShowForOpponent(opponent: Player) -> Bool {
        guard let card = Cards.by(cardId: getCardId()) else { return false }
        return CardUtils.mayCardBeRelevant(card: card, format: AppDelegate.instance().coreManager.game.currentFormat, playerClass: opponent.originalClass) && getRelatedCards(player: opponent).count >= 2
    }

    func getRelatedCards(player: Player) -> [Card?] {
        return player.spellsPlayedCards
            .filter { $0.info.created }
            .compactMap { CardUtils.getProcessedCardFromEntity($0, player) }
    }
}
