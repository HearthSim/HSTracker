//
//  ServantsOfCthun.swift
//  HSTracker
//
//  Created by Francisco Moraes on 10/13/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

// "Summon two 2/3 Fanatics with Taunt."
class ServantsOfCthun: ICardWithRelatedCards {
    required init() {}

    func getCardId() -> String {
        return CardIds.NonCollectible.Neutral.CThunEyeoftheEmpire_ServantsOfCthunToken
    }

    func shouldShowForOpponent(opponent: Player) -> Bool {
        return false
    }

    func getRelatedCards(player: Player) -> [Card?] {
        return [
            Cards.any(byId: CardIds.NonCollectible.Neutral.CThunEyeoftheEmpire_FacelessFanaticToken),
            Cards.any(byId: CardIds.NonCollectible.Neutral.CThunEyeoftheEmpire_FacelessFanaticToken)
        ]
    }
}
