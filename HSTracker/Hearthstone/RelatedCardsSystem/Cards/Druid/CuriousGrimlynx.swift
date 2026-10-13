//
//  CuriousGrimlynx.swift
//  HSTracker
//
//  Created by Francisco Moraes on 10/13/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

// "Taunt. Battlecry: Summon a {0}/{1} Beast with Rush. (It has the opposite stats of this minion!)"
class CuriousGrimlynx: ICardWithRelatedCards {
    required init() {}

    func getCardId() -> String {
        return CardIds.Collectible.Druid.TwistedGrimlynx_CuriousGrimlynxToken
    }

    func shouldShowForOpponent(opponent: Player) -> Bool {
        return false
    }

    func getRelatedCards(player: Player) -> [Card?] {
        return [
            Cards.any(byId: CardIds.NonCollectible.Druid.TwistedGrimlynx)
        ]
    }
}
