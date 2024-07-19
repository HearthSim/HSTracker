//
//  BattlegroundsCompStats.swift
//  HSTracker
//
//  Created by Francisco Moraes on 7/12/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

struct BattlegroundsCompStats: Decodable {
    var data: BattlegroundsCompData
    
    struct BattlegroundsCompData: Decodable {
        var first_place_comps_lobby_races: [LobbyComp]
    }
    
    struct LobbyComp: Decodable {
        var id: Int
        var popularity: Double
        var name: String?
        var key_minions_top3: [Int]?
        var avg_final_placement: Double
    }
}
