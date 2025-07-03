//
//  EternalBloodpetal.swift
//  HSTracker
//
//  Created by Francisco Moraes on 7/3/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class EternalBloodpetal: ICardWithRelatedCards {
    required init() {}

    func getCardId() -> String {
        CardIds.Collectible.Druid.EternalBloodpetal
    }

    func shouldShowForOpponent(opponent: Player) -> Bool {
        false
    }

    func getRelatedCards(player: Player) -> [Card?] {
        return [
            Cards.by(cardId: CardIds.NonCollectible.Druid.EternalBloodpetal_EternalSeedlingToken)
        ]
    }
}
