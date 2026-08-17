//
//  BattlegroundsAnomalyGuides.swift
//  HSTracker
//
//  Created by Francisco Moraes on 8/13/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

// Field names verified against HDT's AnomalyGuidesApiResponse.cs
// (BattlegroundsAnomalyGuide), not inferred.
struct BattlegroundsAnomalyGuide: Decodable {
    var id: Int
    var anomaly: Int
    var published_guide: String
    // Kept as a raw string, not Date - see BattlegroundsCompGuides.swift for
    // why (no dateDecodingStrategy configured, wire format unconfirmed).
    var last_updated: String?
    var favorable_tribes: [Int]?
    var hidden: Bool
    var published_guide_length: Int
    var ready: Bool
}

typealias BattlegroundsAnomalyGuidesData = [BattlegroundsAnomalyGuide]
