//
//  BattlegroundsSingleHeroPickStats.swift
//  HSTracker
//
//  Created by Francisco Moraes on 12/18/22.
//  Copyright © 2022 Benjamin Michotte. All rights reserved.
//

import Foundation

struct BattlegroundsSingleHeroPickStats: Decodable {
    var hero_dbf_id: Int
    var tier: Int?
    var pick_rate: Double
    var avg_placement: Double
    var placement_distribution: [Double]
    var first_place_comp_popularity: [BattlegroundsComposition]
    var mmr_filter_value: String
    var min_mmr: Int
    var total_games_all_heroes: Int64
}
