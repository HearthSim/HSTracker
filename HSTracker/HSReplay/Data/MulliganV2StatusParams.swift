//
//  MulliganV2StatusParams.swift
//  HSTracker
//
//  Created by Francisco Moraes on 8/9/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

struct MulliganV2StatusParams: Encodable {
    struct Deck: Encodable {
        var deckstring: String
        var dbf_ids: [Int]
    }

    // Matches the API's actual required field name (confirmed via a live
    // 400 response: {"deck_boxes":["This field is required."]}) - not
    // "decks", which silently produced an empty/malformed request instead
    // of a compile error since Codable just encodes whatever the property
    // is named.
    var deck_boxes: [Deck]
    var game_type: Int
    var star_level: Int?
    var player_region: String
}
