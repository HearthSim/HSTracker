//
//  YrelBeaconOfHope.swift
//  HSTracker
//
//  Created by Francisco Moraes on 11/8/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class YrelBeaconOfHope: ICardWithRelatedCards {

    func getCardId() -> String {
        return CardIds.Collectible.Paladin.YrelBeaconOfHope
    }

    func shouldShowForOpponent(opponent: Player) -> Bool {
        return false
    }

    func getRelatedCards(player: Player) -> [Card?] {
        return [
            Cards.by(cardId: CardIds.Collectible.Paladin.LibramOfWisdom),
            Cards.by(cardId: CardIds.Collectible.Paladin.LibramOfJustice),
            Cards.by(cardId: CardIds.Collectible.Paladin.LibramOfHope)
        ]
    }

    required init() {
    }
}
