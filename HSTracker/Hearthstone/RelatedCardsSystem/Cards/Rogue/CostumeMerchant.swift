//
//  CostumeMerchant.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/9/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class CostumeMerchant: ICardWithRelatedCards {
    func getCardId() -> String {
        CardIds.Collectible.Rogue.CostumeMerchant
    }

    private let masks: [Card?] = [
        Cards.by(cardId: CardIds.Collectible.Druid.PantherMask),
        Cards.by(cardId: CardIds.Collectible.Hunter.DevilsaurMask),
        Cards.by(cardId: CardIds.Collectible.Mage.SheepMask),
        Cards.by(cardId: CardIds.Collectible.Priest.BehemothMask),
        Cards.by(cardId: CardIds.Collectible.Warlock.BatMask)
    ]

    func shouldShowForOpponent(opponent: Player) -> Bool {
        return false
    }

    func getRelatedCards(player: Player) -> [Card?] {
        return masks
    }

    required init() { }
}
