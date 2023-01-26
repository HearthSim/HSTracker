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
    var game_language: String
}
