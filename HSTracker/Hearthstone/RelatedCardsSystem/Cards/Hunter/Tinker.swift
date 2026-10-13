//
//  Tinker.swift
//  HSTracker
//
//  Created by Francisco Moraes on 10/13/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

// "Assemble a Mech. Get an 'Overdrive'."
class Tinker: ICardWithRelatedCards {
    required init() {}

    func getCardId() -> String {
        return CardIds.Collectible.Hunter.Tinker
    }

    func shouldShowForOpponent(opponent: Player) -> Bool {
        return false
    }

    func getRelatedCards(player: Player) -> [Card?] {
        return [
            Cards.any(byId: CardIds.NonCollectible.Hunter.Tinker_OverdriveToken)
        ]
    }
}
