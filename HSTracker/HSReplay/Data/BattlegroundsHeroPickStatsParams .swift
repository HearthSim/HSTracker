//
//   public class BattlegroundsHeroPickStatsParams .swift
//  HSTracker
//
//  Created by Francisco Moraes on 12/18/22.
//  Copyright © 2022 Benjamin Michotte. All rights reserved.
//

import Foundation

struct BattlegroundsHeroPickStatsParams: Codable {
    var hero_dbf_ids: [Int]
    var minion_types: [Int]
    var anomaly_dbf_id: Int?
    var game_language: String
    var battlegrounds_rating: Int?
    var include_toast = true
    var is_reroll: Bool
}
