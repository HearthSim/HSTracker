//
//  InfestedBreath.swift
//  HSTracker
//
//  Created by Francisco Moraes on 3/27/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class InfestedBreath: LeechGenerator, ICardWithRelatedCards {
    required override init() {
        
    }
    
    func getCardId() -> String {
        return CardIds.Collectible.Deathknight.InfestedBreath
    }

    func shouldShowForOpponent(opponent: Player) -> Bool {
        return false
    }
}
