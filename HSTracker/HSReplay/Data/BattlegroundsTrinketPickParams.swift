//
//  BattlegroundsTrinketPickParams.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/25/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

struct BattlegroundsTrinketPickParams: Codable {
    var hero_dbf_id: Int
    var hero_power_dbf_ids: [Int]
    var minion_types: [Int]
    var anomaly_dbf_id: Int?
    var turn: Int
    var source_dbf_id: Int
    var offered_trinkets: [OfferedTrinket]
    var game_language: String
    var game_type: Int
    var battlegrounds_rating: Int?
    
    struct OfferedTrinket: Codable {
        var trinket_dbf_id: Int
        var extra_data: Int?
    }
}
