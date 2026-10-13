//
//  XelnothBehemoth.swift
//  HSTracker
//
//  Created by Francisco Moraes on 10/13/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

// "Deathrattle: Summon two random 1-Cost minions. Give your minions +3 Attack."
class XelnothBehemoth: Cost1MinionPool {
    override func getCardId() -> String { CardIds.Collectible.Deathknight.XelnothBehemoth }
    override func picks() -> Int { 1 }
    override func eventCount() -> Int { 2 }
    override func isWithReplacement() -> Bool { true }
}
