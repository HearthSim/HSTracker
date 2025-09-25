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
            let game = AppDelegate.instance().coreManager.game
            return card.isCardLegal(gameType: game.currentGameType, format: game.currentFormatType) && getRelatedCards(player: opponent).count > 2
        }
        return false
    }

    func getRelatedCards(player: Player) -> [Card?] {
        return player.cardsPlayedThisMatch
            .compactMap { CardUtils.getProcessedCardFromEntity($0, player) }
            .filter { card in
                card.isDraenei() && card.id != getCardId() &&
                (card.mechanics.contains("BATTLECRY") || card.mechanics.contains("DEATHRATTLE"))
            }
    }

    required init() {
    }
}
