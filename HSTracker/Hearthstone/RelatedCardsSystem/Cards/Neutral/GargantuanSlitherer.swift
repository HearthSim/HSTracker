//
//  GargantuanSlitherer.swift
//  HSTracker
//
//  Created by Francisco Moraes on 10/13/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

// "Taunt Battlecry: Choose a C'Thun ability to trigger."
class GargantuanSlitherer: CthunAbilityCard {
    override func getCardId() -> String {
        return CardIds.Collectible.Neutral.GargantuanSlitherer
    }
}
