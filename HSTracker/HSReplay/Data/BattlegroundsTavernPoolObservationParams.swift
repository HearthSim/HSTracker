//
//  BattlegroundsTavernPoolObservationParams.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/24/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

// HSReplay-API-Client's BattlegroundsTavernPoolObservationParams. The optional
// fields are left out of the JSON when nil, as its DefaultValueHandling.Ignore
// does.
struct BattlegroundsTavernPoolObservationParams: Encodable {
    // The BnetGameType of the current game.
    var game_type: Int
    // The battlegrounds rating (MMR) before the match.
    var battlegrounds_rating: Int?
    // The player region. ("REGION_US", "REGION_EU", "REGION_KR", "REGION_CN")
    var player_region: String?
    // Races available during the battlegrounds game.
    var minion_types: [Int]
    // The active anomaly during the battlegrounds game.
    var anomaly_dbf_id: Int?
    // The lobby-wide deity during the battlegrounds game.
    var deity_dbf_id: Int?
    // The build number of the Hearthstone client.
    var hearthstone_build: Int?
    // The minions and tavern spells of the game's BattlegroundsMinionPool message, including banned cards.
    var tavern_guide_pool: [TavernGuidePoolEntry]

    struct TavernGuidePoolEntry: Encodable {
        var dbf_id: Int
        var tier: Int
        var card_type: Int
        var minion_types: [Int]
        var banned: Bool
    }
}
