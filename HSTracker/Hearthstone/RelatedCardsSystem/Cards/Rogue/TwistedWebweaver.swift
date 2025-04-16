//
//  TwistedWebweaver.swift
//  HSTracker
//
//  Created by Francisco Moraes on 4/16/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class TwistedWebweaver: ICardWithRelatedCards {
    required init() {
        
    }
    
    func getCardId() -> String {
        return CardIds.Collectible.Rogue.TwistedWebweaver
    }

    func shouldShowForOpponent(opponent: Player) -> Bool {
        return false
    }

    func getRelatedCards(player: Player) -> [Card?] {
        return player.cardsPlayedThisMatch
            .compactMap { entity in CardUtils.getProcessedCardFromEntity(entity, player) }
            .filter { card in card.type == .minion }
            .unique()
            .sorted { $0.cost < $1.cost }
    }
}
