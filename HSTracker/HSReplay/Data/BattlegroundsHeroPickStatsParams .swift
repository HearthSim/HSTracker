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
    var deity_dbf_id: Int?
    var game_language: String
    var battlegrounds_rating: Int?
    var include_toast = true
    var is_reroll: Bool
    // The hero_pick_ref returned by the previous hero pick response of this game, if any.
    var hero_pick_ref: String?
}
