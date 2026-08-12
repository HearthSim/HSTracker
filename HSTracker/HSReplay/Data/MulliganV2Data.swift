//
//  MulliganV2Data.swift
//  HSTracker
//
//  Created by Francisco Moraes on 8/7/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

// Shape ported from HDT's MulliganV2Data (Mulligan G-V2 commit); the backend
// contract lives in a closed-source HSReplay.dll, so verify against a live
// response before shipping. Enums fall back to `.unknown` on unrecognized
// values instead of failing the whole decode.
class MulliganV2Data: Decodable {
    var data: GeneralData

    class GeneralData: Decodable {
        var general_info: GeneralInfo
        var cards_by_position: [String: MulliganCard]
    }

    class GeneralInfo: Decodable {
        var deck_status: DeckStatus
    }

    class MulliganCard: Decodable {
        var dbf_id: Int
        var card_status: OfferedCardStatus
        // Keyed by a stringified dbfId combination, e.g. "[]", "[118222]",
        // "[118222, 121064]" - one entry per "if you also keep exactly these
        // other cards" scenario. Parse the key with MulliganJustification.parseKey(_:).
        var justification: [String: Double]
        var tips: [MulliganTip]

        init(dbf_id: Int = 0, card_status: OfferedCardStatus = .valid, justifications: [String: Double] = [:], tips: [MulliganTip] = []) {
            self.dbf_id = dbf_id
            self.card_status = card_status
            self.justification = justifications
            self.tips = tips
        }
    }

    class MulliganTip: Decodable {
        var tip_enum: Int
        var arrows: Int
        var dbf_id: Int?
        var base_keep_rate: Double?
        var adjusted_keep_rate: Double?
        var keep_rate_delta: Double?
        var opponent_class: String?
        var this_opponent_keep_rate: Double?
        var other_opponent_keep_rate: Double?
        // Confirmed against a live response: the API sends "this_init_keep_rate"/
        // "other_init_keep_rate", not the "_initiative_" spelling HDT's C# property
        // names would suggest.
        var this_init_keep_rate: Double?
        var other_init_keep_rate: Double?

        init(tip_enum: Int, arrows: Int, dbf_id: Int? = nil, base_keep_rate: Double? = nil, adjusted_keep_rate: Double? = nil, keep_rate_delta: Double? = nil, opponent_class: String? = nil, this_opponent_keep_rate: Double? = nil, other_opponent_keep_rate: Double? = nil, this_init_keep_rate: Double? = nil, other_init_keep_rate: Double? = nil) {
            self.tip_enum = tip_enum
            self.arrows = arrows
            self.dbf_id = dbf_id
            self.base_keep_rate = base_keep_rate
            self.adjusted_keep_rate = adjusted_keep_rate
            self.keep_rate_delta = keep_rate_delta
            self.opponent_class = opponent_class
            self.this_opponent_keep_rate = this_opponent_keep_rate
            self.other_opponent_keep_rate = other_opponent_keep_rate
            self.this_init_keep_rate = this_init_keep_rate
            self.other_init_keep_rate = other_init_keep_rate
        }
    }
}

enum DeckStatus: String, Decodable {
    case supported = "SUPPORTED"
    case partial = "PARTIAL"
    case none = "NONE"
    case unknown

    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = DeckStatus(rawValue: raw) ?? .unknown
    }
}

enum OfferedCardStatus: String, Decodable {
    case valid = "VALID"
    case lowData = "LOW_DATA"
    case validWithInvalidNeighbors = "VALID_WITH_INVALID_NEIGHBORS"
    case lowDataWithInvalidNeighbors = "LOW_DATA_WITH_INVALID_NEIGHBORS"
    case unknownCard = "UNKNOWN_CARD"
    case noData = "NO_DATA"
    case unknown

    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = OfferedCardStatus(rawValue: raw) ?? .unknown
    }
}
