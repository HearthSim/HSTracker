//
//  WallowTheWretched.swift
//  HSTracker
//
//  Created by Francisco Moraes on 6/23/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class WallowTheWretched: ICardWithRelatedCards {
    required init() {}

    func getCardId() -> String {
        CardIds.Collectible.Warlock.WallowTheWretched
    }

    func shouldShowForOpponent(opponent: Player) -> Bool {
        guard let card = Cards.by(cardId: getCardId()) else {
            return false
        }
        let game = AppDelegate.instance().coreManager.game
        return CardUtils.mayCardBeRelevant(card: card, gameType: game.currentGameType, format: game.currentFormatType, playerClass: opponent.originalClass) && getRelatedCards(player: opponent).count > 1
    }

    func getRelatedCards(player: Player) -> [Card?] {
        if player.isLocalPlayer {
            return player.revealedEntities
                .filter { entity in
                    entity.has(tag: GameTag.is_nightmare_bonus) &&
                    !entity.isInSetAside && !entity.isInZone(zone: Zone.removedfromgame)
                }
                .compactMap { entity in CardUtils.getProcessedCardFromEntity(entity, player) }
                .filter { $0?.type == .spell }
        }

        let opponentDarkGiftEnchantments = player.revealedEntities.filter { entity in
            entity.has(tag: GameTag.is_nightmare_bonus) &&
            entity[GameTag.cardtype] == CardType.enchantment.rawValue
        }

        return player.revealedEntities
            .filter { entity in
                entity.has(tag: GameTag.is_nightmare_bonus) &&
                !entity.isInSetAside && !entity.isInZone(zone: Zone.removedfromgame) &&
                opponentDarkGiftEnchantments.contains { $0[GameTag.creator] == entity.id }
            }
            .compactMap { entity in CardUtils.getProcessedCardFromEntity(entity, player) }
            .filter { $0?.type == .spell }
    }
}
