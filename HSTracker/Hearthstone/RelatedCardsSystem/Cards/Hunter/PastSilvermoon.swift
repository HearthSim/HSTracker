//
//  PastSilvermoon.swift
//  HSTracker
//
//  Created by Francisco Moraes on 11/4/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

class PastSilvermoon: ICardWithRelatedCards {
    func getCardId() -> String {
        CardIds.Collectible.Hunter.PastSilvermoon
    }

    func shouldShowForOpponent(opponent: Player) -> Bool {
        false
    }

    func getRelatedCards(player: Player) -> [Card?] {
        [
            Cards.by(cardId: CardIds.NonCollectible.Hunter.PastSilvermoon_PresentSilvermoonToken),
            Cards.by(cardId: CardIds.NonCollectible.Hunter.PastSilvermoon_FutureSilvermoonToken)
        ]
    }

    required init() {}
}

class PresentSilvermoon: ICardWithRelatedCards {
    func getCardId() -> String {
        CardIds.NonCollectible.Hunter.PastSilvermoon_PresentSilvermoonToken
    }

    func shouldShowForOpponent(opponent: Player) -> Bool {
        false
    }

    func getRelatedCards(player: Player) -> [Card?] {
        [
            Cards.by(cardId: CardIds.NonCollectible.Hunter.PastSilvermoon_FutureSilvermoonToken)
        ]
    }

    required init() {}
}
