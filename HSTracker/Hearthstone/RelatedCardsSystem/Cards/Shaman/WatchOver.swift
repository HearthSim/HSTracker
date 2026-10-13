//
//  WatchOver.swift
//  HSTracker
//
//  Created by Francisco Moraes on 10/13/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

// "Choose two different C'Thun abilities to trigger."
class WatchOver: CthunAbilityCard {
    override func getCardId() -> String {
        return CardIds.Collectible.Shaman.WatchOver
    }
}
