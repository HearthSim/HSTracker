//
//  SpiritGatherer.swift
//  HSTracker
//
//  Created by Francisco Moraes on 3/27/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class SpiritGatherer: ICardWithRelatedCards {
    required init() {
        
    }
    
    private let wisp: [Card?] = [
        Cards.any(byId: CardIds.NonCollectible.Mage.WispTokenEMERALD_DREAM)
    ]
    
    func getCardId() -> String {
        return CardIds.Collectible.Mage.SpiritGatherer
    }
    
    func shouldShowForOpponent(opponent: Player) -> Bool {
        return false
    }
    
    func getRelatedCards(player: Player) -> [Card?] {
        return wisp
    }
}
