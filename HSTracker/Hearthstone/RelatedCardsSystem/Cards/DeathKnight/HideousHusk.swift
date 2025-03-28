//
//  HideousHusk.swift
//  HSTracker
//
//  Created by Francisco Moraes on 3/27/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class HideousHusk: LeechGenerator, ICardWithRelatedCards {
    required override init() {
        
    }
    
    func getCardId() -> String {
        return CardIds.Collectible.Deathknight.HideousHusk
    }

    func shouldShowForOpponent(opponent: Player) -> Bool {
        return false
    }
}
