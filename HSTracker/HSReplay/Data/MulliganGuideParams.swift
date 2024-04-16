//
//  MulliganGuideParams.swift
//  HSTracker
//
//  Created by Francisco Moraes on 2/19/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class MulliganGuideParams: Encodable {
    var deckstring: String
    var game_type: Int
    var format_type: Int
    var opponent_class: String
    var player_initiative: String
    var player_star_level: Int?
    var player_star_multiplier: Int?
    var player_region: String?
    
    init(deckstring: String, game_type: Int, format_type: Int, opponent_class: String, player_initiative: String, player_star_level: Int? = nil, player_star_multiplier: Int? = nil, player_region: String? = nil) {
        self.deckstring = deckstring
        self.game_type = game_type
        self.format_type = format_type
        self.opponent_class = opponent_class
        self.player_initiative = player_initiative
        self.player_star_level = player_star_level
        self.player_star_multiplier = player_star_multiplier
        self.player_region = player_region
    }
}

class MulliganGuideFeedbackParams: MulliganGuideParams {
    var offered_cards: [Int]
    var kept_cards: [Int]
    var final_cards_in_hand: [Int]
    var mulligan_guide_visible: Bool?
    var final_state: Int?
    
    init(deckstring: String, game_type: Int, format_type: Int, opponent_class: String, player_initiative: String, player_star_level: Int?, player_region: String?, offered_cardsa: [Int], kept_cards: [Int], final_cards_in_hand: [Int], mulligan_guide_visible: Bool?, final_state: Int?) {
        self.offered_cards = offered_cardsa
        self.kept_cards = kept_cards
        self.final_cards_in_hand = final_cards_in_hand
        self.mulligan_guide_visible = mulligan_guide_visible
        self.final_state = final_state
        super.init(deckstring: deckstring, game_type: game_type, format_type: format_type, opponent_class: opponent_class, player_initiative: player_initiative)
    }
}
