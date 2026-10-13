//
//  TentacleLash.swift
//  HSTracker
//
//  Created by Francisco Moraes on 10/13/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

// "After your hero attacks, reduce the Cost of C'Thun by (1). Choose a C'Thun ability to trigger."
class TentacleLash: CthunAbilityCard {
    override func getCardId() -> String {
        return CardIds.Collectible.DemonHunter.TentacleLash
    }
}
