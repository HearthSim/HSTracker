//
//  ProtoPandaren.swift
//  HSTracker
//
//  Created by Francisco Moraes on 10/13/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

// "After a card enters your hand except from this, give both players a random spell."
class ProtoPandaren: SpellPool {
    override func getCardId() -> String { CardIds.Collectible.Neutral.ProtoPandaren }
    override func picks() -> Int { 1 }
    override func isWithReplacement() -> Bool { true }
}
