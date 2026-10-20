//
//  BattlegroundsCompGuides.swift
//  HSTracker
//
//  Created by Francisco Moraes on 8/13/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

// Field names verified against the HSReplayNET client source
// (HSReplay.Responses.BattlegroundsCompGuide), not inferred from HDT's C#
// property names - see BattlegroundsCompsGuidesViewModel.cs for the
// (differently-cased) consumer side.
struct BattlegroundsCompGuide: Decodable {
    var name: String
    var tier: Int
    var tier_rank: Int
    var adjusted_tier: Int?
    var difficulty: Int
    var primary_tribe: Int
    var representative_card: String
    var core_cards: [Int]
    var addon_cards: [Int]
    // Only sent with the Tier7 guides, already filtered by the server.
    var minions_to_pin: [Int]?
    var how_to_play: String
    var when_to_commit: String
    var common_enablers: String
    // Kept as a raw string rather than Date: HSReplayAPI.parseResponse uses a
    // plain JSONDecoder with no dateDecodingStrategy configured, and the wire
    // format (ISO8601 vs. epoch) isn't confirmed - parse/format at the call
    // site once a guide screen actually needs to display it.
    var last_updated: String
}

typealias BattlegroundsCompGuidesData = [BattlegroundsCompGuide]

// HSReplay.Requests.BattlegroundsCompGuidesParams.
struct BattlegroundsCompGuidesParams {
    // Empty before a match.
    var minion_types: [Int]
    var anomaly_dbf_id: Int?
    var deity_dbf_id: Int?
    var game_language: String
    var game_type: Int?

    // Built by hand (rather than passing a parameters dict to
    // startAuthorizedRequest/Http) so `minion_types` is repeated once per
    // value, exactly as the HSReplayNET client's ToQueryString does.
    var queryString: String {
        var query = "?game_language=\(game_language)"
        for type in minion_types {
            query += "&minion_types=\(type)"
        }
        if let deity_dbf_id {
            query += "&deity_dbf_id=\(deity_dbf_id)"
        }
        if let anomaly_dbf_id {
            query += "&anomaly_dbf_id=\(anomaly_dbf_id)"
        }
        if let game_type {
            query += "&game_type=\(game_type)"
        }
        return query
    }
}

struct BattlegroundsTier7CompGuidesData: Decodable {
    var by_tier: [Int: [BattlegroundsCompGuide]]
}
