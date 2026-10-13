//
//  EntropicRift.swift
//  HSTracker
//
//  Created by Francisco Moraes on 10/13/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

// "Get two random Shadow Spells."
class EntropicRift: ShadowSpellPool {
    override func getCardId() -> String { CardIds.Collectible.Priest.EntropicRift }
    override func picks() -> Int { 1 }
    override func eventCount() -> Int { 2 }
    override func isWithReplacement() -> Bool { true }
}
