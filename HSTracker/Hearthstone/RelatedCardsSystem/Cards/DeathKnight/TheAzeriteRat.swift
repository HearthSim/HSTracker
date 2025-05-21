//
//  TheAzeriteRat.swift
//  HSTracker
//
//  Created by Francisco Moraes on 5/20/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class TheAzeriteRat: ICardWithRelatedCards {
    required init() {
        
    }
    
    func getCardId() -> String {
        return CardIds.NonCollectible.Deathknight.KoboldMiner_TheAzeriteRatToken
    }

    func shouldShowForOpponent(opponent: Player) -> Bool {
        return false
    }

    func getRelatedCards(player: Player) -> [Card?] {
        guard !player.deadMinionsCards.isEmpty else {
            return []
        }
        
        let highestCost = player.deadMinionsCards.map { $0.card.cost }.max() ?? 0
        
        return player.deadMinionsCards
            .compactMap { CardUtils.getProcessedCardFromEntity($0, player) }
            .filter { $0?.cost == highestCost }
    }
}
