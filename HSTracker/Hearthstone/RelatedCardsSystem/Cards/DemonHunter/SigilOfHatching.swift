//
//  SigilOfHatching.swift
//  HSTracker
//
//  Created by Francisco Moraes on 10/13/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

// "At the start of your next turn, summon three 3/1 Shredclaws with Rush."
class SigilOfHatching: ICardWithRelatedCards {
    required init() {}

    func getCardId() -> String {
        return CardIds.Collectible.DemonHunter.SigilOfHatching
    }

    func shouldShowForOpponent(opponent: Player) -> Bool {
        return false
    }

    func getRelatedCards(player: Player) -> [Card?] {
        return [
            Cards.any(byId: CardIds.NonCollectible.DemonHunter.SigilofHatching_ShredclawToken),
            Cards.any(byId: CardIds.NonCollectible.DemonHunter.SigilofHatching_ShredclawToken),
            Cards.any(byId: CardIds.NonCollectible.DemonHunter.SigilofHatching_ShredclawToken)
        ]
    }
}
