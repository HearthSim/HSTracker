//
//  BattlegroundsQuestStats.swift
//  HSTracker
//
//  Created by Francisco Moraes on 12/6/22.
//  Copyright © 2022 Benjamin Michotte. All rights reserved.
//

import Foundation

struct BattlegroundsQuestStats: Decodable {
    var reward_dbf_id: Int
    var reward_card_dbf_id: Int?
    var avg_final_placement_r: Double?
    var fp_pick_rate_r: Double?
    var first_place_comps: [BattlegroundsComposition]
    var tier_r: Int?
    var mmr_filter_value: String
    var min_mmr: Int?
    var anomaly_adjusted: Bool?
    var debug: [String] 
}
