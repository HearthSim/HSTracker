//
//  DustBunny.swift
//  HSTracker
//
//  Created by Francisco Moraes on 7/31/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class DustBunny: ICardWithRelatedCards {
    required init() {}

    func getCardId() -> String {
        CardIds.Collectible.Rogue.DustBunny
    }

    func shouldShowForOpponent(opponent: Player) -> Bool {
        return false
    }

    func getRelatedCards(player: Player) -> [Card?] {
        return [
            Cards.by(cardId: CardIds.NonCollectible.Neutral.TheCoinBasic),
            Cards.by(cardId: CardIds.NonCollectible.Neutral.KoboldMiner_RockToken),
            Cards.by(cardId: CardIds.NonCollectible.Neutral.KingMukla_BananasToken),
            Cards.by(cardId: CardIds.NonCollectible.Rogue.WickedKnifeLegacy)
        ]
    }
}
