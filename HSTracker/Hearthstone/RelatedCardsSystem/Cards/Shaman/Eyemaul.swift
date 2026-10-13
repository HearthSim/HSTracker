//
//  Eyemaul.swift
//  HSTracker
//
//  Created by Francisco Moraes on 10/13/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

// "After your hero attacks, summon two 2/2 Elementals with Rush."
class Eyemaul: ICardWithRelatedCards {
    required init() {}

    func getCardId() -> String {
        return CardIds.Collectible.Shaman.Eyemaul
    }

    func shouldShowForOpponent(opponent: Player) -> Bool {
        return false
    }

    func getRelatedCards(player: Player) -> [Card?] {
        return [
            Cards.any(byId: CardIds.NonCollectible.Shaman.Eyemaul_TremoringElementalToken),
            Cards.any(byId: CardIds.NonCollectible.Shaman.Eyemaul_TremoringElementalToken)
        ]
    }
}
