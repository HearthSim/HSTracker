//
//  Product9.swift
//  HSTracker
//
//  Created by Francisco Moraes on 11/7/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class Product9: ICardWithRelatedCards {
    
    func getCardId() -> String {
        return CardIds.Collectible.Hunter.Product9
    }

    func shouldShowForOpponent(opponent: Player) -> Bool {
        return false
    }

    func getRelatedCards(player: Player) -> [Card?] {
        return player.secretsTriggeredCards
            .compactMap { CardUtils.getProcessedCardFromEntity($0, player) }
            .unique()
            .sorted { $0.cost > $1.cost }
    }

    required init() {
    }
}
