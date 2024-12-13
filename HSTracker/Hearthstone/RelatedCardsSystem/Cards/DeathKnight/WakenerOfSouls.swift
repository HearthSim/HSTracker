//
//  WakenerOfSouls.swift
//  HSTracker
//
//  Created by Francisco Moraes on 11/8/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class WakenerOfSouls: ResurrectionCard {
    
    override func getCardId() -> String {
        return CardIds.Collectible.Deathknight.WakenerOfSouls
    }

    override func filterCard(card: Card) -> Bool {
        return card.mechanics.contains("DEATHRATTLE") && card.id != CardIds.Collectible.Deathknight.WakenerOfSouls
    }

    override func resurrectsMultipleCards() -> Bool {
        return false
    }

    required init() {
    }
}
