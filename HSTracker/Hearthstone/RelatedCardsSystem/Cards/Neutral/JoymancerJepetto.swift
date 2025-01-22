//
//  JoymancerJepetto.swift
//  HSTracker
//
//  Created by Francisco Moraes on 1/21/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class JoymancerJepetto: ICardWithRelatedCards {
    
    required init() {
        
    }

    func getCardId() -> String {
        return CardIds.Collectible.Neutral.JoymancerJepetto
    }

    func shouldShowForOpponent(opponent: Player) -> Bool {
        return false
    }

    func getRelatedCards(player: Player) -> [Card?] {
        return player.cardsPlayedThisMatch
            .compactMap { CardUtils.getProcessedCardFromEntity($0, player) }
            .filter { $0.type == .minion && ($0.attack == 1 || $0.health == 1) }
    }
}
