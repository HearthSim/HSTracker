//
//  TimeAdmralHooktail.swift
//  HSTracker
//
//  Created by Francisco Moraes on 11/4/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

class TimeAdmralHooktail: ICardWithRelatedCards {
    func getCardId() -> String {
        CardIds.Collectible.Rogue.TimeAdmralHooktail
    }

    func shouldShowForOpponent(opponent: Player) -> Bool {
        false
    }

    func getRelatedCards(player: Player) -> [Card?] {
        [
            Cards.by(cardId: CardIds.NonCollectible.Rogue.TimeAdmralHooktail_TimelessChestToken)
        ]
    }

    required init() {}
}
