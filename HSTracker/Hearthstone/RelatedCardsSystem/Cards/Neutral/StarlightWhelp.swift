//
//  StarlightWhelp.swift
//  HSTracker
//
//  Created by Francisco Moraes on 1/24/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class StarlightWhelp: ICardWithRelatedCards {
    func getCardId() -> String {
        return CardIds.Collectible.Neutral.StarlightWhelp
    }

    func shouldShowForOpponent(opponent: Player) -> Bool {
        return false
    }

    func getRelatedCards(player: Player) -> [Card?] {
        return player.startingHand
            .compactMap { CardUtils.getProcessedCardFromEntity($0, player) }
    }

    required init() {}
}
