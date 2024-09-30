//
//  BattlegroundsTrinketPickStats.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/23/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

struct BattlegroundsTrinketPickStats: Decodable {
    var data: [BattlegroundsSingleTrinketPickStats]?
    
    struct BattlegroundsSingleTrinketPickStats: Decodable {
        var trinket_dbf_id: Int
        var extra_data: Int?
        var tier: String?
        var pick_rate: Double?
        var avg_placement: Double?
    }
}
