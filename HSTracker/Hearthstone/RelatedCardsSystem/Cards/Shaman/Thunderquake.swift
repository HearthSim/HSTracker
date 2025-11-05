//
//  Thunderquake.swift
//  HSTracker
//
//  Created by Francisco Moraes on 11/4/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

class Thunderquake: ICardWithRelatedCards {
    func getCardId() -> String {
        CardIds.Collectible.Shaman.Thunderquake
    }

    func shouldShowForOpponent(opponent: Player) -> Bool {
        false
    }

    func getRelatedCards(player: Player) -> [Card?] {
        [
            Cards.by(cardId: CardIds.Collectible.Shaman.StaticShock)
        ]
    }

    required init() {}
}
