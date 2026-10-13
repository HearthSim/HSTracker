//
//  CthunAbilityCard.swift
//  HSTracker
//
//  Created by Francisco Moraes on 10/13/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

// Shared base for cards that trigger one of C'Thun, Eye of the Empire's abilities.
class CthunAbilityCard: ICardWithRelatedCards {
    required init() {}

    func getCardId() -> String {
        fatalError("Must be overridden")
    }

    func shouldShowForOpponent(opponent: Player) -> Bool {
        return false
    }

    func getRelatedCards(player: Player) -> [Card?] {
        return [
            Cards.any(byId: CardIds.NonCollectible.Neutral.CThunEyeoftheEmpire_WrathOfCthunToken),
            Cards.any(byId: CardIds.NonCollectible.Neutral.CThunEyeoftheEmpire_DomainOfCthunToken),
            Cards.any(byId: CardIds.NonCollectible.Neutral.CThunEyeoftheEmpire_GlareOfCthunToken1),
            Cards.any(byId: CardIds.NonCollectible.Neutral.CThunEyeoftheEmpire_ServantsOfCthunToken)
        ]
    }
}
