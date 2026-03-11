//
//  DeathwingWorldbreaker.swift
//  HSTracker
//
//  Created by Francisco Moraes on 3/11/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

class DeathwingWorldbreaker: ICardWithRelatedCards {

    required init() {}

    func getCardId() -> String {
        return CardIds.Collectible.Invalid.DeathwingWorldbreakerHeroic
    }

    private let heroPowerEffects: [Card?] = [
        Cards.by(cardId: CardIds.NonCollectible.Neutral.DragonsReignToken),
        Cards.by(cardId: CardIds.NonCollectible.Neutral.ToppleToken),
        Cards.by(cardId: CardIds.NonCollectible.Neutral.RazeToken),
        Cards.by(cardId: CardIds.NonCollectible.Neutral.EnthrallToken)
    ]

    func shouldShowForOpponent(opponent: Player) -> Bool {
        return false
    }

    func getRelatedCards(player: Player) -> [Card?] {
        return heroPowerEffects
    }
}
