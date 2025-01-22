//
//  Tyr.swift
//  HSTracker
//
//  Created by Francisco Moraes on 11/7/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class Tyr: ICardWithRelatedCards {
    
    func getCardId() -> String {
        return CardIds.Collectible.Paladin.Tyr
    }

    func shouldShowForOpponent(opponent: Player) -> Bool {
        return false
    }

    func getRelatedCards(player: Player) -> [Card?] {
        return player.deadMinionsCards
            .compactMap { CardUtils.getProcessedCardFromEntity($0, player) }
            .unique()
            .filter { $0.isClass(cardClass: player.currentClass ?? .invalid) && $0.attack > 1 && $0.attack < 5 }
            .sorted { $0.cost < $1.cost }
    }

    required init() {
    }
}
