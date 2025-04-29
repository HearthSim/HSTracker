//
//  ContrabandStash.swift
//  HSTracker
//
//  Created by Francisco Moraes on 4/29/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class ContrabandStash: ICardWithRelatedCards {
    required init() {
        
    }
    
    func getCardId() -> String {
        return CardIds.Collectible.Rogue.ContrabandStash
    }

    func shouldShowForOpponent(opponent: Player) -> Bool {
        return false
    }

    func getRelatedCards(player: Player) -> [Card?] {
        return player.cardsPlayedThisMatch
            .compactMap { entity in CardUtils.getProcessedCardFromEntity(entity, player) }
            .filter { card in
                return !card.isClass(cardClass: player.currentClass ?? .invalid) && !card.isNeutral()
            }
            .sorted { $0.cost < $1.cost }
    }
}
