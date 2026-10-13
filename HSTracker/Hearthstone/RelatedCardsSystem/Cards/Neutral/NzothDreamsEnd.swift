//
//  NzothDreamsEnd.swift
//  HSTracker
//
//  Created by Francisco Moraes on 10/13/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

// "Old God Cost (1) less for each Deathrattle minion you've summoned this game."
class NzothDreamsEnd: ICardWithRelatedCards {
    required init() {}

    func getCardId() -> String {
        return CardIds.Collectible.Neutral.NzothDreamsEnd
    }

    func shouldShowForOpponent(opponent: Player) -> Bool {
        return false
    }

    func getRelatedCards(player: Player) -> [Card?] {
        return [
            Cards.any(byId: CardIds.NonCollectible.Neutral.NZothDreamsEnd_CallOfNzothToken),
            Cards.any(byId: CardIds.NonCollectible.Neutral.NZothDreamsEnd_MasteryOfNzothToken),
            Cards.any(byId: CardIds.NonCollectible.Neutral.NZothDreamsEnd_ArmyOfNzothToken),
            Cards.any(byId: CardIds.NonCollectible.Neutral.NZothDreamsEnd_DomainOfNzothToken1)
        ]
    }
}
