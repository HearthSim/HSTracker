//
//  YshaarjTitanBane.swift
//  HSTracker
//
//  Created by Francisco Moraes on 10/13/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

// "Old God. Battlecry: If you've spent 30 Mana on minions this game, gain Immune for 1 turn."
class YshaarjTitanBane: ICardWithRelatedCards {
    required init() {}

    func getCardId() -> String {
        return CardIds.Collectible.Neutral.YshaarjTitanBane
    }

    func shouldShowForOpponent(opponent: Player) -> Bool {
        return false
    }

    func getRelatedCards(player: Player) -> [Card?] {
        return [
            Cards.any(byId: CardIds.NonCollectible.Neutral.YShaarjTitanBane_GazeOfYshaarjToken),
            Cards.any(byId: CardIds.NonCollectible.Neutral.YShaarjTitanBane_SpawnOfYshaarjToken),
            Cards.any(byId: CardIds.NonCollectible.Neutral.YShaarjTitanBane_MightOfYshaarjToken),
            Cards.any(byId: CardIds.NonCollectible.Neutral.YShaarjTitanBane_DomainOfYshaarjToken1)
        ]
    }
}
