//
//  DeitySnapshot.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/22/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

/// One hero's Deity as it was last seen: the card it will awaken as, the stats it had
/// grown to, and whether Mask of Ancient Ones will make it golden.
class DeitySnapshot {
    let card: Card
    let attack: Int
    let health: Int
    let isGolden: Bool
    let turn: Int

    init(card: Card, attack: Int, health: Int, isGolden: Bool, turn: Int) {
        self.card = card
        self.attack = attack
        self.health = health
        self.isGolden = isGolden
        self.turn = turn
    }
}
