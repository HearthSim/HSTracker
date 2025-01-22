//
//  TramHeist.swift
//  HSTracker
//
//  Created by Francisco Moraes on 1/21/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class TramHeist: ICardWithRelatedCards {
    required init() {
        
    }

    func getCardId() -> String {
        return CardIds.Collectible.Priest.TramHeist
    }

    func shouldShowForOpponent(opponent: Player) -> Bool {
        return false
    }

    func getRelatedCards(player: Player) -> [Card?] {
        let game = AppDelegate.instance().coreManager.game
        let opponent: Player! = game.player.id == player.id ? game.opponent : game.player

        return opponent.cardsPlayedLastTurn
            .compactMap { CardUtils.getProcessedCardFromEntity($0, opponent) }
            .sorted { $0.cost > $1.cost }
    }
}
