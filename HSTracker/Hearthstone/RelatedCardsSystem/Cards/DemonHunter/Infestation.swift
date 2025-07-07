//
//  Infestation.swift
//  HSTracker
//
//  Created by Francisco Moraes on 7/7/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class Infestation: ICardWithRelatedCards {
    required init() {}

    func getCardId() -> String {
        CardIds.Collectible.DemonHunter.Infestation
    }

    func shouldShowForOpponent(opponent: Player) -> Bool {
        false
    }

    func getRelatedCards(player: Player) -> [Card?] {
        return [
            Cards.any(byId: CardIds.NonCollectible.DemonHunter.GorishiWasp_GorishiStingerToken),
            Cards.any(byId: CardIds.NonCollectible.DemonHunter.GorishiWasp_GorishiStingerToken)
        ]
    }
}
