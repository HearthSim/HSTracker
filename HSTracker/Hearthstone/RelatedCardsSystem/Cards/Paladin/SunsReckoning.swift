//
//  SunsReckoning.swift
//  HSTracker
//
//  Created by Francisco Moraes on 10/13/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

// "Deal 1 damage to all enemy minions. Shuffle 'Final Reckoning' into your deck."
class SunsReckoning: ICardWithRelatedCards {
    required init() {}

    func getCardId() -> String {
        return CardIds.Collectible.Paladin.SunsReckoning
    }

    func shouldShowForOpponent(opponent: Player) -> Bool {
        return false
    }

    func getRelatedCards(player: Player) -> [Card?] {
        return [
            Cards.any(byId: CardIds.NonCollectible.Paladin.SunsReckoning_FinalReckoningToken)
        ]
    }
}
