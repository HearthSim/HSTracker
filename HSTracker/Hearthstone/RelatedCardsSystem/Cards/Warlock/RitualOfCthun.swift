//
//  RitualOfCthun.swift
//  HSTracker
//
//  Created by Francisco Moraes on 10/13/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

// "In 2 turns, choose a C'Thun ability to trigger."
class RitualOfCthun: CthunAbilityCard {
    override func getCardId() -> String {
        return CardIds.Collectible.Warlock.RitualOfCthun
    }
}
