//
//  BrilliantMacaw.swift
//  HSTracker
//
//  Created by Francisco Moraes on 4/29/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class BrilliantMacaw: ICardWithRelatedCards {
    required init() {
        
    }
    
    func getCardId() -> String {
        return CardIds.Collectible.Shaman.BrilliantMacaw
    }

    func shouldShowForOpponent(opponent: Player) -> Bool {
        return false
    }

    func getRelatedCards(player: Player) -> [Card?] {
        let lastBattlecry = player.cardsPlayedThisMatch
            .compactMap { entity in CardUtils.getProcessedCardFromEntity(entity, player) }
            .last { card in
                guard let mechanics = card?.mechanics else { return false }
                return mechanics.contains("Battlecry")
            }
        if let lastBattlecry {
            return [lastBattlecry]
        } else {
            return [Card?]()
        }
    }
}
