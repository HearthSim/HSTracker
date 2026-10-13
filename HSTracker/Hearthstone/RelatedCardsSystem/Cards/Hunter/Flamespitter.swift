//
//  Flamespitter.swift
//  HSTracker
//
//  Created by Francisco Moraes on 10/13/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

// "After your hero attacks, get an 'Overdrive'."
class Flamespitter: ICardWithRelatedCards {
    required init() {}

    func getCardId() -> String {
        return CardIds.Collectible.Hunter.Flamespitter
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
