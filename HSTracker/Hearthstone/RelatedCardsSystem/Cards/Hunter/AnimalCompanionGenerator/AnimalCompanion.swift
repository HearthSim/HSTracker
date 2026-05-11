//
//  AnimalCompanion.swift
//  HSTracker
//
//  Created by Francisco Moraes on 5/11/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

class AnimalCompanion: AnimalCompanionGenerator, ICardWithRelatedCards {

    required override init() {}

    func getCardId() -> String {
        return CardIds.Collectible.Hunter.AnimalCompanionCore
    }

    func shouldShowForOpponent(opponent: Player) -> Bool {
        return false
    }
}

class AnimalCompanionLegacy: AnimalCompanionGenerator, ICardWithRelatedCards {

    required override init() {}

    func getCardId() -> String {
        return CardIds.Collectible.Hunter.AnimalCompanionLegacy
    }

    func shouldShowForOpponent(opponent: Player) -> Bool {
        return false
    }
}

class AnimalCompanionVanilla: AnimalCompanionGenerator, ICardWithRelatedCards {

    required override init() {}

    func getCardId() -> String {
        return CardIds.Collectible.Hunter.AnimalCompanionVanilla
    }

    func shouldShowForOpponent(opponent: Player) -> Bool {
        return false
    }
}
