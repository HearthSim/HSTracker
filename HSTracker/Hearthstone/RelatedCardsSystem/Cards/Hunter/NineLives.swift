//
//  NineLives.swift
//  HSTracker
//
//  Created by Francisco Moraes on 6/23/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class NineLives: ResurrectionCard {
    required init() {}

    override func getCardId() -> String {
        CardIds.Collectible.Hunter.NineLives
    }

    override func filterCard(card: Card) -> Bool {
        card.hasDeathrattle()
    }

    override func resurrectsMultipleCards() -> Bool {
        false
    }
}
