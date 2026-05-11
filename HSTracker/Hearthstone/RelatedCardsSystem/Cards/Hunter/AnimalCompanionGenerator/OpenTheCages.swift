//
//  OpenTheCages.swift
//  HSTracker
//
//  Created by Francisco Moraes on 5/11/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

class OpenTheCages: AnimalCompanionGenerator, ICardWithRelatedCards {

    required override init() {}

    func getCardId() -> String {
        return CardIds.Collectible.Hunter.OpenTheCages
    }

    func shouldShowForOpponent(opponent: Player) -> Bool {
        return false
    }
}
