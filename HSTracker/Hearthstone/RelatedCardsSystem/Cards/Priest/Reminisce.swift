//
//  Reminisce.swift
//  HSTracker
//
//  Created by Francisco Moraes on 2/9/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

class Reminisce: ICardWithRelatedCards {

    required init() {}

    func getCardId() -> String {
        return CardIds.NonCollectible.Priest.Reminisce
    }

    func shouldShowForOpponent(opponent: Player) -> Bool {
        return false
    }

    func getRelatedCards(player: Player) -> [Card?] {
        let game = AppDelegate.instance().coreManager.game
        let opponent = game.player.id == player.id ? game.opponent : game.player

        return opponent?.cardsPlayedThisMatch
            .compactMap { entity in CardUtils.getProcessedCardFromEntity(entity, player) }
            .suffix(2) ?? [Card?]()
    }
}
