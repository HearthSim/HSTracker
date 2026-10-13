//
//  ArmyOfNzoth.swift
//  HSTracker
//
//  Created by Francisco Moraes on 10/13/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

// "Resurrect 4 different Deathrattle minions." - N'Zoth, Dream's End's ability.
// "Different" means each resurrected minion is distinct, so the grid is de-duplicated.
class ArmyOfNzoth: ResurrectionCard {
    override func getCardId() -> String {
        return CardIds.NonCollectible.Neutral.NZothDreamsEnd_ArmyOfNzothToken
    }

    override func filterCard(card: Card) -> Bool {
        return card.type == .minion && card.hasDeathrattle()
    }

    override func resurrectsMultipleCards() -> Bool {
        return false
    }

    required init() {
    }
}
