//
//  BattlegroundsCompStatsParams.swift
//  HSTracker
//
//  Created by Francisco Moraes on 7/12/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

struct BattlegroundsCompStatsParams: Codable {
    var minion_types: [Int]
    var deity_dbf_id: Int?
    var game_language: String
    var include_toast: Bool = true
}
