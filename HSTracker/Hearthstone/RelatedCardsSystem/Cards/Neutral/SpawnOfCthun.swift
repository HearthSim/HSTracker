//
//  SpawnOfCthun.swift
//  HSTracker
//
//  Created by Francisco Moraes on 10/13/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

// "Battlecry: If C'Thun started in your deck, choose one of its abilities to trigger."
class SpawnOfCthun: CthunAbilityCard {
    override func getCardId() -> String {
        return CardIds.Collectible.Neutral.SpawnOfCthun
    }
}
