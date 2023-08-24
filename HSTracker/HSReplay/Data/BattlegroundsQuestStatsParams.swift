//
//  BattlegroundsQuestStatsParams.swift
//  HSTracker
//
//  Created by Francisco Moraes on 12/12/22.
//  Copyright © 2022 Benjamin Michotte. All rights reserved.
//

import Foundation

struct BattlegroundsQuestStatsParams: Codable {
    var hero_dbf_id: Int
    var hero_power_dbf_ids: [Int]
    var turn: Int
    var minion_types: [Int]
    var anomaly_dbf_id: Int?
    var offered_rewards: [OfferedReward]
    var game_language: String
    
    struct OfferedReward: Codable {
        var reward_dbf_id: Int
        var reward_card_dbf_id: Int?
    }
}
