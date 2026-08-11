//
//  MulliganV2Params.swift
//  HSTracker
//
//  Created by Francisco Moraes on 8/7/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

// Field names ported from HDT's MulliganV2Params (Mulligan G-V2 commit); the
// backend contract lives in a closed-source HSReplay.dll, so verify against a
// live response before shipping.
class MulliganV2Params: Encodable {
    var deckstring: String
    var player_class: String
    var deck_cards: [Int]
    var opponent_class: String
    var player_initiative: String
    var player_region: String?
    var player_star_level: Int?
    var player_star_multiplier: Int?
    var game_type: Int
    var format_type: Int
    var offered_cards: [Int]?
    var mulligan_state: Int

    init(deckstring: String, player_class: String, deck_cards: [Int], opponent_class: String, player_initiative: String, player_region: String? = nil, player_star_level: Int? = nil, player_star_multiplier: Int? = nil, game_type: Int, format_type: Int, offered_cards: [Int]? = nil, mulligan_state: Int) {
        self.deckstring = deckstring
        self.player_class = player_class
        self.deck_cards = deck_cards
        self.opponent_class = opponent_class
        self.player_initiative = player_initiative
        self.player_region = player_region
        self.player_star_level = player_star_level
        self.player_star_multiplier = player_star_multiplier
        self.game_type = game_type
        self.format_type = format_type
        self.offered_cards = offered_cards
        self.mulligan_state = mulligan_state
    }
}
