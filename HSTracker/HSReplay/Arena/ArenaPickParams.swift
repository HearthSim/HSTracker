//
//  ArenaPickParams.swift
//  HSTracker
//
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

/// Request bodies for the three arena pick endpoints. Keys match the
/// `JsonProperty` names in HSReplay-API-Client's `Requests/Arena*Params.cs`.
///
/// `redraft_number`, `deck_card_ids` and `picked_hero_power_card_id` are
/// `DefaultValueHandling.Ignore` on the C# side, so they are optional here and
/// omitted when nil rather than encoded as null.
struct ArenaHeroPickParams: Encodable {
    let picked_hero_card_ids: [String]
    let offered_hero_card_ids: [String]
    let player_region: Int
    let account_lo: Int64
    let arena_season: Int
    let deck_id: Int64
    let game_type: Int
}

struct ArenaCardPickParams: Encodable {
    let picked_hero_card_id: String
    let picked_card_ids: [String]
    let offered_card_ids: [String]
    let player_region: Int
    let account_lo: Int64
    let arena_season: Int
    let deck_id: Int64
    let game_type: Int
    var redraft_number: Int?
    var deck_card_ids: [String]?
    var picked_hero_power_card_id: String?
}

struct ArenaScoreDeckParams: Encodable {
    let picked_hero_card_id: String
    let deck_card_ids: [String]
    let player_region: Int
    let account_lo: Int64
    let arena_season: Int
    let deck_id: Int64
    let game_type: Int
    var redraft_number: Int?
    var picked_hero_power_card_id: String?
}
