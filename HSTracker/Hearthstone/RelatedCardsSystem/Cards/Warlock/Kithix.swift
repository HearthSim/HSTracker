//
//  Kithix.swift
//  HSTracker
//
//  Created by Francisco Moraes on 10/13/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

// "Battlecry: If you've completed a Ritual this game, choose a Sinister Ritual to begin."
class Kithix: ICardWithRelatedCards {
    required init() {}

    func getCardId() -> String {
        return CardIds.Collectible.Warlock.Kithix
    }

    func shouldShowForOpponent(opponent: Player) -> Bool {
        return false
    }

    func getRelatedCards(player: Player) -> [Card?] {
        return [
            Cards.any(byId: CardIds.NonCollectible.Warlock.Kithix_RitualOfFamineToken),
            Cards.any(byId: CardIds.NonCollectible.Warlock.Kithix_RitualOfSubjugationToken),
            Cards.any(byId: CardIds.NonCollectible.Warlock.Kithix_RitualOfConquestToken)
        ]
    }
}
