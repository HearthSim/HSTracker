//
//  SanguineInfestation.swift
//  HSTracker
//
//  Created by Francisco Moraes on 3/27/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class SanguineInfestation: LeechGenerator, ICardWithRelatedCards {
    override required init() {
        
    }
    
    func getCardId() -> String {
        return CardIds.Collectible.Deathknight.SanguineInfestation
    }

    func shouldShowForOpponent(opponent: Player) -> Bool {
        return false
    }
}
