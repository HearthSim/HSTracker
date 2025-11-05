//
//  PastGnomeregan.swift
//  HSTracker
//
//  Created by Francisco Moraes on 11/4/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

class PastGnomeregan: ICardWithRelatedCards {
    func getCardId() -> String {
        CardIds.Collectible.Paladin.PastGnomeregan
    }

    func shouldShowForOpponent(opponent: Player) -> Bool {
        false
    }

    func getRelatedCards(player: Player) -> [Card?] {
        [
            Cards.by(cardId: CardIds.NonCollectible.Paladin.PastGnomeregan_PresentGnomereganToken),
            Cards.by(cardId: CardIds.NonCollectible.Paladin.PastGnomeregan_FutureGnomereganToken)
        ]
    }

    required init() {}
}

class PresentGnomeregan: ICardWithRelatedCards {
    func getCardId() -> String {
        CardIds.NonCollectible.Paladin.PastGnomeregan_PresentGnomereganToken
    }

    func shouldShowForOpponent(opponent: Player) -> Bool {
        false
    }

    func getRelatedCards(player: Player) -> [Card?] {
        [
            Cards.by(cardId: CardIds.NonCollectible.Paladin.PastGnomeregan_FutureGnomereganToken)
        ]
    }

    required init() {}
}
