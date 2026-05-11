//
//  CallOfTheWild.swift
//  HSTracker
//
//  Created by Francisco Moraes on 5/11/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

class CallOfTheWild: AnimalCompanionGenerator, ICardWithRelatedCards {

    required override init() {}

    func getCardId() -> String {
        return CardIds.Collectible.Hunter.CallOfTheWild
    }

    func shouldShowForOpponent(opponent: Player) -> Bool {
        return false
    }
}

class CallOfTheWildCore: AnimalCompanionGenerator, ICardWithRelatedCards {

    required override init() {}

    func getCardId() -> String {
        return CardIds.Collectible.Hunter.CallOfTheWildCore
    }

    func shouldShowForOpponent(opponent: Player) -> Bool {
        return false
    }
}
