//
//  FerociousFelbat.swift
//  HSTracker
//
//  Created by Francisco Moraes on 3/27/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class FerociousFelbat: ResurrectionCard {
    override func getCardId() -> String {
        return CardIds.Collectible.DemonHunter.FerociousFelbat
    }

    override func filterCard(card: Card) -> Bool {
        return card.mechanics.contains("DEATHRATTLE") && card.cost >= 5
    }

    override func resurrectsMultipleCards() -> Bool {
        return false
    }
}

