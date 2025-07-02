//
//  CreatureOfTheSacredCave.swift
//  HSTracker
//
//  Created by Francisco Moraes on 7/2/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class CreatureOfTheSacredCave: ICardWithRelatedCards {
    required init() {}

    func getCardId() -> String {
        CardIds.Collectible.Paladin.CreatureOfTheSacredCave
    }

    func shouldShowForOpponent(opponent: Player) -> Bool {
        false
    }

    func getRelatedCards(player: Player) -> [Card?] {
        return player.cardsPlayedThisTurn
            .compactMap { CardUtils.getProcessedCardFromEntity($0, player) }
            .filter { $0.spellSchool == SpellSchool.holy }
    }
}
