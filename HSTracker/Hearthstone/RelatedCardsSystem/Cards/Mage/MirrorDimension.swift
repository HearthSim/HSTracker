//
//  MirrorDimension.swift
//  HSTracker
//
//  Created by Francisco Moraes on 11/4/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

class MirrorDimension: ICardWithRelatedCards {
    func getCardId() -> String {
        CardIds.Collectible.Mage.MirrorDimension
    }

    func shouldShowForOpponent(opponent: Player) -> Bool {
        false
    }

    func getRelatedCards(player: Player) -> [Card?] {
        [
            Cards.by(cardId: CardIds.NonCollectible.Mage.MirrorDimension_MirroredMageToken)
        ]
    }

    required init() {}
}
