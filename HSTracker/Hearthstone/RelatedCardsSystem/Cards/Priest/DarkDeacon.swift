//
//  DarkDeacon.swift
//  HSTracker
//
//  Created by Francisco Moraes on 10/13/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

// "Battlecry: If you've cast 2 Shadow spells while holding this, choose a C'Thun ability to trigger."
class DarkDeacon: CthunAbilityCard {
    override func getCardId() -> String {
        return CardIds.Collectible.Priest.DarkDeacon
    }
}
