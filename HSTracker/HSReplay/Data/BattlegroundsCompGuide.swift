//
//  BattlegroundsCompsGuides.swift
//  HSTracker
//
//  Created by Francisco Moraes on 1/4/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

struct BattlegroundsCompGuide: Decodable {
    var id: Int
    var name: String
    var tier: Int
    var difficulty: Int
    var core_cards: [Int]
    var addon_cards: [Int]
    var how_to_play: String
    var when_to_commit: String
    var common_enablers: String
    var last_updated: String
}
