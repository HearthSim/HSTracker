//
//  SkyscreamerEggs.swift
//  HSTracker
//
//  Created by Francisco Moraes on 7/3/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class SkyscreamerEggs: ICardWithRelatedCards {
    required init() {}

    func getCardId() -> String {
        CardIds.Collectible.Druid.SkyscreamerEggs
    }

    func shouldShowForOpponent(opponent: Player) -> Bool {
        false
    }

    func getRelatedCards(player: Player) -> [Card?] {
        return [
            Cards.any(byId: CardIds.NonCollectible.Druid.SkyscreamerEggs_SkyscreamerHatchlingToken),
            Cards.any(byId: CardIds.NonCollectible.Druid.SkyscreamerEggs_SkyscreamerHatchlingToken),
            Cards.any(byId: CardIds.NonCollectible.Druid.SkyscreamerEggs_SkyscreamerHatchlingToken),
            Cards.any(byId: CardIds.NonCollectible.Druid.SkyscreamerEggs_SkyscreamerHatchlingToken)
        ]
    }
}
