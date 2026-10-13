//
//  MarchToWar.swift
//  HSTracker
//
//  Created by Francisco Moraes on 10/13/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

// "All numbers on this card equal your remaining Mana. Summon a 1/1 Soldier with Divine Shield."
class MarchToWar: ICardWithRelatedCards {
    required init() {}

    func getCardId() -> String {
        return CardIds.Collectible.Paladin.MarchToWar
    }

    func shouldShowForOpponent(opponent: Player) -> Bool {
        return false
    }

    func getRelatedCards(player: Player) -> [Card?] {
        return [
            Cards.any(byId: CardIds.NonCollectible.Paladin.MarchtoWar_VanirSoldierToken)
        ]
    }
}
