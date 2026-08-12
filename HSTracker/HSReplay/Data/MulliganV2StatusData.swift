//
//  MulliganV2StatusData.swift
//  HSTracker
//
//  Created by Francisco Moraes on 8/9/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

struct MulliganV2StatusData: Decodable {

    enum Status: String {
        case NONE,
             SUPPORTED,
             PARTIAL
    }

    // Matches the API's real response shape, confirmed live:
    // {"data":[{"deckstring":"...","status":"SUPPORTED","cards_unsupported":0}, ...]}
    // - a flat array under "data", not a dictionary keyed by deckstring.
    struct Deck: Decodable {
        var deckstring: String
        var status: String
        var cards_unsupported: Int
    }

    var data: [Deck]
}
