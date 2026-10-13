//
//  ElderWordManifest.swift
//  HSTracker
//
//  Created by Francisco Moraes on 10/13/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

// "Summon a 5/5 Voidwing with Lifesteal. (The next Shadow spell you play repeats this!)"
class ElderWordManifest: ICardWithRelatedCards {
    required init() {}

    func getCardId() -> String {
        return CardIds.Collectible.Priest.ElderWordManifest
    }

    func shouldShowForOpponent(opponent: Player) -> Bool {
        return false
    }

    func getRelatedCards(player: Player) -> [Card?] {
        return [
            Cards.any(byId: CardIds.NonCollectible.Priest.ElderWordManifest_VoidwingToken)
        ]
    }
}
