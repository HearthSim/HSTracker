//
//  RaDen.swift
//  HSTracker
//
//  Created by Francisco Moraes on 1/21/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class RaDen: ICardWithRelatedCards {
    required init() {
        
    }

    func getCardId() -> String {
        return CardIds.Collectible.Priest.RaDen
    }

    func shouldShowForOpponent(opponent: Player) -> Bool {
        return false
    }

    func getRelatedCards(player: Player) -> [Card?] {
        return player.cardsPlayedThisMatch
            .filter { $0.info.created && $0.cardId != getCardId() }
            .compactMap { CardUtils.getProcessedCardFromEntity($0, player) }
            .filter { $0.type == .minion }
            .sorted { $0.cost > $1.cost }
    }
}
