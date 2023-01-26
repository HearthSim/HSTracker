//
//  BattlegroundsComposition.swift
//  HSTracker
//
//  Created by Francisco Moraes on 12/6/22.
//  Copyright © 2022 Benjamin Michotte. All rights reserved.
//

import Foundation

struct BattlegroundsComposition: Decodable {
    var id: Int
    var key_minions_top3: [Int]
    var name: String
    var popularity: Double
    var is_valid: Bool
}
