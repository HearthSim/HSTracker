//
//  KingMaluk.swift
//  HSTracker
//
//  Created by Francisco Moraes on 11/4/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

class KingMaluk: ICardWithRelatedCards {
    func getCardId() -> String {
        CardIds.Collectible.Hunter.KingMaluk
    }

    func shouldShowForOpponent(opponent: Player) -> Bool {
        false
    }

    func getRelatedCards(player: Player) -> [Card?] {
        [Cards.by(cardId: CardIds.NonCollectible.Hunter.KingMaluk_InfiniteBananaToken)]
    }

    required init() {}
}
