//
//  JaceDarkweaver.swift
//  HSTracker
//
//  Created by Francisco Moraes on 6/23/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class JaceDarkweaver: ICardWithRelatedCards {
    required init() {}

    func getCardId() -> String {
        CardIds.Collectible.DemonHunter.JaceDarkweaver
    }

    func shouldShowForOpponent(opponent: Player) -> Bool {
        guard let card = Cards.by(cardId: getCardId()) else {
            return false
        }
        let game = AppDelegate.instance().coreManager.game
        return CardUtils.mayCardBeRelevant(card: card, format: game.currentFormat, playerClass: opponent.originalClass) &&
               getRelatedCards(player: opponent).count > 3
    }

    func getRelatedCards(player: Player) -> [Card?] {
        player.spellsPlayedCards
            .compactMap { CardUtils.getProcessedCardFromEntity($0, player) }
            .filter { $0.spellSchool == SpellSchool.fel }
    }
}
