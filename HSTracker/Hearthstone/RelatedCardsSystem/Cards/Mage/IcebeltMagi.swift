//
//  IcebeltMagi.swift
//  HSTracker
//
//  Created by Francisco Moraes on 10/13/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

// "Battlecry: Draw two cards. For each that isn't a minion, summon a 3/6 Water Elemental."
class IcebeltMagi: ICardWithRelatedCards {
    required init() {}

    func getCardId() -> String {
        return CardIds.Collectible.Mage.IcebeltMagi
    }

    func shouldShowForOpponent(opponent: Player) -> Bool {
        return false
    }

    func getRelatedCards(player: Player) -> [Card?] {
        return [
            Cards.any(byId: CardIds.Collectible.Mage.WaterElemental)
        ]
    }
}
