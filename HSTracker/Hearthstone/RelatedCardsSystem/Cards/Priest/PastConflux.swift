//
//  PastConflux.swift
//  HSTracker
//
//  Created by Francisco Moraes on 11/4/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

class PastConflux: ICardWithRelatedCards {
    func getCardId() -> String {
        CardIds.Collectible.Priest.PastConflux
    }

    func shouldShowForOpponent(opponent: Player) -> Bool {
        false
    }

    func getRelatedCards(player: Player) -> [Card?] {
        [
            Cards.by(cardId: CardIds.NonCollectible.Priest.PastConflux_PresentConfluxToken),
            Cards.by(cardId: CardIds.NonCollectible.Priest.PastConflux_FutureConfluxToken)
        ]
    }

    required init() {}
}

class PresentConflux: ICardWithRelatedCards {
    func getCardId() -> String {
        CardIds.NonCollectible.Priest.PastConflux_PresentConfluxToken
    }

    func shouldShowForOpponent(opponent: Player) -> Bool {
        false
    }

    func getRelatedCards(player: Player) -> [Card?] {
        [
            Cards.by(cardId: CardIds.NonCollectible.Priest.PastConflux_FutureConfluxToken)
        ]
    }

    required init() {}
}
