//
//  Sleetbreaker.swift
//  HSTracker
//
//  Created by Francisco Moraes on 7/31/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class Sleetbreaker: ICardWithRelatedCards {
    required init() {}

    func getCardId() -> String {
        CardIds.Collectible.Shaman.Sleetbreaker
    }

    func shouldShowForOpponent(opponent: Player) -> Bool {
        return false
    }

    func getRelatedCards(player: Player) -> [Card?] {
        return [
            Cards.by(cardId: CardIds.Collectible.Shaman.Windchill)
        ]
    }
}
