//
//  ForgeOfOrigination.swift
//  HSTracker
//
//  Created by Francisco Moraes on 10/13/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

// "Summon a 3/3 Golem with Taunt. Spend 3 Armor to give it +3/+3."
class ForgeOfOrigination: ICardWithRelatedCards {
    required init() {}

    func getCardId() -> String {
        return CardIds.Collectible.Warrior.ForgeOfOrigination
    }

    func shouldShowForOpponent(opponent: Player) -> Bool {
        return false
    }

    func getRelatedCards(player: Player) -> [Card?] {
        return [
            Cards.any(byId: CardIds.NonCollectible.Warrior.ForgeofOrigination_SteelGolemToken)
        ]
    }
}
