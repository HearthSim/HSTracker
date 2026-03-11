//
//  RitualOfPower.swift
//  HSTracker
//
//  Created by Francisco Moraes on 3/11/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

class RitualOfPower: ICardWithRelatedCards {

    required init() {}

    func getCardId() -> String {
        return CardIds.Collectible.Shaman.RitualOfPower
    }

    func shouldShowForOpponent(opponent: Player) -> Bool {
        return false
    }

    func getRelatedCards(player: Player) -> [Card?] {
        return [
            Cards.by(cardId: CardIds.NonCollectible.Shaman.RitualofPower_BreezlingToken)
        ]
    }
}
