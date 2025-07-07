//
//  GorishiWasp.swift
//  HSTracker
//
//  Created by Francisco Moraes on 7/7/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class GorishiWasp: ICardWithRelatedCards {
    required init() {}

    func getCardId() -> String {
        CardIds.Collectible.DemonHunter.GorishiWasp
    }

    func shouldShowForOpponent(opponent: Player) -> Bool {
        false
    }

    func getRelatedCards(player: Player) -> [Card?] {
        return [
            Cards.any(byId: CardIds.NonCollectible.DemonHunter.GorishiWasp_GorishiStingerToken)
        ]
    }
}
