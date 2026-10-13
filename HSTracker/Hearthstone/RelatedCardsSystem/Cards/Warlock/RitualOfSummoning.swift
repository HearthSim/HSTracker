//
//  RitualOfSummoning.swift
//  HSTracker
//
//  Created by Francisco Moraes on 10/13/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

// "In 2 turns, summon two 3/5 C'thraxxi with Taunt."
class RitualOfSummoning: ICardWithRelatedCards {
    required init() {}

    func getCardId() -> String {
        return CardIds.Collectible.Warlock.RitualOfSummoning
    }

    func shouldShowForOpponent(opponent: Player) -> Bool {
        return false
    }

    func getRelatedCards(player: Player) -> [Card?] {
        return [
            Cards.any(byId: CardIds.NonCollectible.Warlock.RitualofSummoning_CthraxBruteToken),
            Cards.any(byId: CardIds.NonCollectible.Warlock.RitualofSummoning_CthraxBruteToken)
        ]
    }
}
