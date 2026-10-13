//
//  ClockworkBoars.swift
//  HSTracker
//
//  Created by Francisco Moraes on 10/13/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

// "Summon two 1/1 Mech Beasts with Charge."
class ClockworkBoars: ICardWithRelatedCards {
    required init() {}

    func getCardId() -> String {
        return CardIds.Collectible.Hunter.ClockworkBoars
    }

    func shouldShowForOpponent(opponent: Player) -> Bool {
        return false
    }

    func getRelatedCards(player: Player) -> [Card?] {
        return [
            Cards.any(byId: CardIds.NonCollectible.Hunter.ClockworkBoars_ClockworkBoarToken),
            Cards.any(byId: CardIds.NonCollectible.Hunter.ClockworkBoars_ClockworkBoarToken)
        ]
    }
}
