//
//  TessGreymane.swift
//  HSTracker
//
//  Created by Francisco Moraes on 11/7/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class TessGreymane: ICardWithRelatedCards {
    
    func getCardId() -> String {
        return CardIds.Collectible.Rogue.TessGreymane
    }

    func shouldShowForOpponent(opponent: Player) -> Bool {
        return false
    }

    func getRelatedCards(player: Player) -> [Card?] {
        return player.cardsPlayedThisMatch
            .compactMap { CardUtils.getProcessedCardFromEntity($0, player) }
            .filter { $0.isClass(cardClass: player.currentClass ?? .invalid) == false && $0.isNeutral() == false }
            .sorted { $0.cost < $1.cost }
    }

    required init() {
    }
}
