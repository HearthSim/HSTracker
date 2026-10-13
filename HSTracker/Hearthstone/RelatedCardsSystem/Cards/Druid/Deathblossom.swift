//
//  Deathblossom.swift
//  HSTracker
//
//  Created by Francisco Moraes on 10/13/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

// "Get two 2/1 Plants with 'Deathrattle: Summon a 5/5 Bug with Taunt.' They cost (2)."
class Deathblossom: ICardWithRelatedCards {
    required init() {}

    func getCardId() -> String {
        return CardIds.Collectible.Druid.Deathblossom
    }

    func shouldShowForOpponent(opponent: Player) -> Bool {
        return false
    }

    func getRelatedCards(player: Player) -> [Card?] {
        return [
            Cards.any(byId: CardIds.NonCollectible.Druid.Deathblossom_CarnivorousPlantToken),
            Cards.any(byId: CardIds.NonCollectible.Druid.Deathblossom_CarnivorousPlantToken)
        ]
    }
}
