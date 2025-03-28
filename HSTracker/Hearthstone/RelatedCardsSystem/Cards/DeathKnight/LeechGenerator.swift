//
//  LeechGenerator.swift
//  HSTracker
//
//  Created by Francisco Moraes on 3/27/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class LeechGenerator {
    fileprivate let leech: [Card?] = [
        Cards.any(byId: CardIds.NonCollectible.Deathknight.HideousHusk_BloatedLeechToken)
    ]
    
    func getRelatedCards(player: Player) -> [Card?] {
        return leech
    }
}
