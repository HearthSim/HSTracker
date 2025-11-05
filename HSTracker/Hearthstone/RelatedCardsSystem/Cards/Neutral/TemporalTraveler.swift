//
//  TemporalTraveler.swift
//  HSTracker
//
//  Created by Francisco Moraes on 11/4/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

class TemporalTraveler: ICardWithRelatedCards {
    func getCardId() -> String {
        CardIds.Collectible.Neutral.TemporalTraveler
    }

    func shouldShowForOpponent(opponent: Player) -> Bool {
        false
    }

    func getRelatedCards(player: Player) -> [Card?] {
        [Cards.by(cardId: CardIds.NonCollectible.Neutral.TemporalTraveler_TemporalShadowToken)]
    }

    required init() {}
}
