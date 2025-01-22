//
//  Mixtape.swift
//  HSTracker
//
//  Created by Francisco Moraes on 1/21/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

class Mixtape: ICardWithRelatedCards {

    required init() {
        
    }

    func getCardId() -> String {
        return CardIds.Collectible.Rogue.Mixtape
    }

    func shouldShowForOpponent(opponent: Player) -> Bool {
        return false
    }

    func getRelatedCards(player: Player) -> [Card?] {
        let game = AppDelegate.instance().coreManager.game
        let opponent: Player! = game.player.id == player.id ? game.opponent : game.player

        return opponent.cardsPlayedThisMatch
            .compactMap { CardUtils.getProcessedCardFromEntity($0, opponent) }
            .unique()
    }
}
