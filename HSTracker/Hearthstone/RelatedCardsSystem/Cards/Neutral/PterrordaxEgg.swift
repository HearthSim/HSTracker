//
//  PterrordaxEgg.swift
//  HSTracker
//
//  Created by Francisco Moraes on 7/2/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class PterrordaxEgg: ICardWithRelatedCards {
    private let token: [Card?] = [
        Cards.any(byId: CardIds.NonCollectible.Neutral.PterrordaxEgg_JuvenilePterrordaxToken)
    ]

    required init() {}

    func getCardId() -> String {
        CardIds.Collectible.Neutral.PterrordaxEgg
    }

    func shouldShowForOpponent(opponent: Player) -> Bool {
        false
    }

    func getRelatedCards(player: Player) -> [Card?] {
        token
    }
}
