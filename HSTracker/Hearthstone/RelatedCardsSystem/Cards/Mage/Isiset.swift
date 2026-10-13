//
//  Isiset.swift
//  HSTracker
//
//  Created by Francisco Moraes on 10/13/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

// "Battlecry: Summon two 10/10 Constructs. They are Frozen until you spend 15 Mana on spells."
class Isiset: ICardWithRelatedCards {
    required init() {}

    func getCardId() -> String {
        return CardIds.Collectible.Mage.Isiset
    }

    func shouldShowForOpponent(opponent: Player) -> Bool {
        return false
    }

    func getRelatedCards(player: Player) -> [Card?] {
        return [
            Cards.any(byId: CardIds.NonCollectible.Mage.ColossusOfTheCold),
            Cards.any(byId: CardIds.NonCollectible.Mage.ColossusOfTheCold)
        ]
    }
}
