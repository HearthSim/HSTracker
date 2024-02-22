//
//  MulliganGuideStatusParams.swift
//  HSTracker
//
//  Created by Francisco Moraes on 2/19/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

struct MulliganGuideStatusParams: Encodable {
    var decks: [String]
    var game_type: Int
    var star_level: Int?
}
