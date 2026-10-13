//
//  DarkestDepths.swift
//  HSTracker
//
//  Created by Francisco Moraes on 10/13/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

// "Summon two 0/3 Guards with Taunt. Assemble a minion."
class DarkestDepths: ICardWithRelatedCards {
    required init() {}

    func getCardId() -> String {
        return CardIds.Collectible.Warlock.DarkestDepths
    }

    func shouldShowForOpponent(opponent: Player) -> Bool {
        return false
    }

    func getRelatedCards(player: Player) -> [Card?] {
        return [
            Cards.any(byId: CardIds.NonCollectible.Warlock.DarkestDepths_DepthguardToken),
            Cards.any(byId: CardIds.NonCollectible.Warlock.DarkestDepths_DepthguardToken)
        ]
    }
}
