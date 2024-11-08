//
//  VelenLeaderOfTheExiled.swift
//  HSTracker
//
//  Created by Francisco Moraes on 11/8/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class VelenLeaderOfTheExiled: ICardWithRelatedCards {
    
    func getCardId() -> String {
        return CardIds.Collectible.Neutral.VelenLeaderOfTheExiled
    }

    func shouldShowForOpponent(opponent: Player) -> Bool {
        if let card = Cards.by(cardId: getCardId()) {
            return CardUtils.isCardFromFormat(card: card, format: AppDelegate.instance().coreManager.game.currentFormat) && getRelatedCards(player: opponent).count > 2
        }
        return false
    }

    func getRelatedCards(player: Player) -> [Card?] {
        return player.cardsPlayedThisMatch
            .compactMap { Cards.by(cardId: $0.cardId) }
            .filter { card in
                card.isDraenei() && card.id != getCardId() &&
                (card.mechanics.contains("BATTLECRY") || card.mechanics.contains("DEATHRATTLE"))
            }
    }

    required init() {
    }
}
