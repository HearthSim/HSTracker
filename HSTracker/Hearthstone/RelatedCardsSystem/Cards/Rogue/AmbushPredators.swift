//
//  AmbushPredators.swift
//  HSTracker
//
//  Created by Francisco Moraes on 7/3/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class AmbushPredators: ICardWithRelatedCards {
    required init() {}

    func getCardId() -> String {
        CardIds.Collectible.Rogue.AmbushPredators
    }

    func shouldShowForOpponent(opponent: Player) -> Bool {
        false
    }

    func getRelatedCards(player: Player) -> [Card?] {
        return [
            Cards.any(byId: CardIds.NonCollectible.Rogue.AmbushPredators_VenomousSpitterToken)
        ]
    }
}
