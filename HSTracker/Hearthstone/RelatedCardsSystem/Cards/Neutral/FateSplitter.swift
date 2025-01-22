//
//  FateSplitter.swift
//  HSTracker
//
//  Created by Francisco Moraes on 1/21/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class FateSplitter: ICardWithRelatedCards {

    required init() {
    }

    func getCardId() -> String {
        return CardIds.Collectible.Neutral.FateSplitter
    }

    func shouldShowForOpponent(opponent: Player) -> Bool {
        return false
    }

    func getRelatedCards(player: Player) -> [Card?] {
        let game = AppDelegate.instance().coreManager.game
        let opponent: Player! = game.player.id == player.id ? game.opponent : game.player

        if let lastCard = opponent.cardsPlayedThisMatch
            .compactMap({ CardUtils.getProcessedCardFromEntity($0, opponent) })
            .last {
            return [lastCard]
        }
        
        return []
    }
}
