//
//  Nythendra.swift
//  HSTracker
//
//  Created by Francisco Moraes on 3/27/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class Nythendra: ICardWithRelatedCards {
    required init() {
        
    }
    
    private let nythendricBeetle: [Card?] = [
        Cards.any(byId: CardIds.NonCollectible.Deathknight.Nythendra_NythendricBeetleToken)
    ]

    func getCardId() -> String {
        return CardIds.Collectible.Deathknight.Nythendra
    }

    func getRelatedCards(player: Player) -> [Card?] {
        return nythendricBeetle
    }

    func shouldShowForOpponent(opponent: Player) -> Bool {
        return false
    }
}
