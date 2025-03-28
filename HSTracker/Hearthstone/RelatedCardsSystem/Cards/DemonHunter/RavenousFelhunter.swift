//
//  RavenousFelhunter.swift
//  HSTracker
//
//  Created by Francisco Moraes on 3/27/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class RavenousFelhunter: ResurrectionCard {
    override func getCardId() -> String {
        return CardIds.Collectible.DemonHunter.RavenousFelhunter
    }

    override func filterCard(card: Card) -> Bool {
        return card.mechanics.contains("DEATHRATTLE") && card.cost <= 4
    }

    override func resurrectsMultipleCards() -> Bool {
        return false
    }
}
