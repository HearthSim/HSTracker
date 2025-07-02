//
//  Resuscitate.swift
//  HSTracker
//
//  Created by Francisco Moraes on 7/2/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class Resuscitate: ResurrectionCard {
    override func getCardId() -> String {
        CardIds.Collectible.Priest.Resuscitate
    }

    override func filterCard(card: Card) -> Bool {
        card.cost <= 3
    }

    override func resurrectsMultipleCards() -> Bool {
        false
    }
}
