//
//  BattlegroundsHeroPickStats.swift
//  HSTracker
//
//  Created by Francisco Moraes on 5/18/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

struct BattlegroundsHeroPickStats: Decodable {
    var data: [BattlegroundsSingleHeroPickStats]
    var toast: BattlegroundsHeroPickToast
    
    struct BattlegroundsSingleHeroPickStats: Decodable {
        var hero_dbf_id: Int
        var tier_v2: String?
        var pick_rate: Double?
        var avg_placement: Double?
        var placement_distribution: [Double]?
        var first_place_comp_popularity: [BattlegroundsComposition]?
    }
    
    struct BattlegroundsHeroPickToast: Decodable {
        var min_mmr: Int?
        var mmr_filter_value: String?
        var anomaly_adjusted: Bool?
        var parameters: [String: String]
    }
}
