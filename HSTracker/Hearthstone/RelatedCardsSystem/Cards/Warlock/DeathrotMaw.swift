//
//  DeathrotMaw.swift
//  HSTracker
//
//  Created by Francisco Moraes on 7/2/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class DeathrotMaw: ICardWithRelatedCards {
    private let felBeasts: [Card?] = [
        Cards.any(byId: CardIds.NonCollectible.Warlock.EscapetheUnderfel_FelscreamerToken),
        Cards.any(byId: CardIds.NonCollectible.Warlock.EscapetheUnderfel_FelraptorToken),
        Cards.any(byId: CardIds.NonCollectible.Warlock.EscapetheUnderfel_FelhornToken)
    ]

    required init() {}

    func getCardId() -> String {
        CardIds.Collectible.Warlock.DeathrotMaw
    }

    func shouldShowForOpponent(opponent: Player) -> Bool {
        false
    }

    func getRelatedCards(player: Player) -> [Card?] {
        felBeasts
    }
}
