//
//  UnleashTheCrocolisks.swift
//  HSTracker
//
//  Created by Francisco Moraes on 11/4/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

class UnleashTheCrocolisks: ICardWithRelatedCards {
    func getCardId() -> String {
        CardIds.Collectible.Warrior.UnleashTheCrocolisks
    }

    func shouldShowForOpponent(opponent: Player) -> Bool {
        false
    }

    func getRelatedCards(player: Player) -> [Card?] {
        [
            Cards.by(cardId: CardIds.NonCollectible.Warrior.UnleashtheCrocolisks_ColiseumCrocoliskToken)
        ]
    }

    required init() {}
}
