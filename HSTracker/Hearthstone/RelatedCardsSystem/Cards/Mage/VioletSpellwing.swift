//
//  VioletSpellwing.swift
//  HSTracker
//
//  Created by Francisco Moraes on 7/31/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class VioletSpellwing: ICardWithRelatedCards {
    required init() {}

    func getCardId() -> String {
        CardIds.Collectible.Mage.VioletSpellwing
    }

    func shouldShowForOpponent(opponent: Player) -> Bool {
        return false
    }

    func getRelatedCards(player: Player) -> [Card?] {
        return [Cards.by(cardId: CardIds.Collectible.Mage.ArcaneMissilesLegacy)]
    }
}
