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
    var difficulty: Int
    var primary_tribe: Int
    var representative_card: String
    var core_cards: [Int]
    var addon_cards: [Int]
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

struct BattlegroundsTier7CompGuidesData: Decodable {
    var by_tier: [Int: [BattlegroundsCompGuide]]
}
