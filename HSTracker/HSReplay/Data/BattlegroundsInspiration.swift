//
//  BattlegroundsInspiration.swift
//  HSTracker
//
//  Created by Francisco Moraes on 8/21/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

// Mirrors HDT's InspirationApiRequestData. Field names are the wire names its
// [JsonProperty] attributes declare, not the C# property names.
//
// minion_types carries Race ordinals the same way BattlegroundsCompStatsParams
// and the trinket/hero pick params do (Race.allCases.firstIndex).
struct BattlegroundsInspirationParams: Codable {
    var minion_types: [Int]
    var key_card_dbf_ids: [Int]
    var game_type: Int
    var lineup_dbf_ids: [Int]
}

// Mirrors InspirationApiResponse. Every field is optional-with-default: HDT's
// records give each property an initializer, so a payload missing one decodes
// rather than failing, and one bad field would otherwise cost the whole panel.
struct BattlegroundsInspiration: Decodable {
    var data: InspirationData

    struct InspirationData: Decodable {
        var lineups: [Lineup]

        enum CodingKeys: String, CodingKey {
            case lineups
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            lineups = try container.decodeIfPresent([Lineup].self, forKey: .lineups) ?? []
        }
    }

    struct Lineup: Decodable {
        var hero_dbf_id: Int
        var starting_hero_power: Int
        var final_lineup: [Minion]

        enum CodingKeys: String, CodingKey {
            case hero_dbf_id, starting_hero_power, final_lineup
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            hero_dbf_id = try container.decodeIfPresent(Int.self, forKey: .hero_dbf_id) ?? 0
            starting_hero_power = try container.decodeIfPresent(Int.self, forKey: .starting_hero_power) ?? 0
            final_lineup = try container.decodeIfPresent([Minion].self, forKey: .final_lineup) ?? []
        }
    }

    struct Minion: Decodable {
        var minion_dbf_id: Int
        // Typed `object` in HDT, which then keeps only the entries where it is
        // actually a number (`x.ZonePosition is long`) - the API uses a
        // non-numeric value for minions that never made it onto the final
        // board. nil here is that same "not on the board" signal.
        var zone_position: Int?
        var attack: Int
        var health: Int
        var premium: Bool
        var divine_shield: Bool
        var taunt: Bool
        // HDT maps the wire's misspelled "venemous" onto its Venomous property.
        var venemous: Bool
        var poison: Bool
        var reborn: Bool
        var windfury: Bool
        var deathrattle: Bool

        enum CodingKeys: String, CodingKey {
            case minion_dbf_id, zone_position, attack, health, premium
            case divine_shield, taunt, venemous, poison, reborn, windfury, deathrattle
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            minion_dbf_id = try container.decodeIfPresent(Int.self, forKey: .minion_dbf_id) ?? 0
            // try? rather than decodeIfPresent: a present-but-not-a-number
            // zone_position must read as nil, not throw.
            zone_position = try? container.decodeIfPresent(Int.self, forKey: .zone_position)
            attack = try container.decodeIfPresent(Int.self, forKey: .attack) ?? 0
            health = try container.decodeIfPresent(Int.self, forKey: .health) ?? 0
            premium = try container.decodeIfPresent(Bool.self, forKey: .premium) ?? false
            divine_shield = try container.decodeIfPresent(Bool.self, forKey: .divine_shield) ?? false
            taunt = try container.decodeIfPresent(Bool.self, forKey: .taunt) ?? false
            venemous = try container.decodeIfPresent(Bool.self, forKey: .venemous) ?? false
            poison = try container.decodeIfPresent(Bool.self, forKey: .poison) ?? false
            reborn = try container.decodeIfPresent(Bool.self, forKey: .reborn) ?? false
            windfury = try container.decodeIfPresent(Bool.self, forKey: .windfury) ?? false
            deathrattle = try container.decodeIfPresent(Bool.self, forKey: .deathrattle) ?? false
        }
    }
}
