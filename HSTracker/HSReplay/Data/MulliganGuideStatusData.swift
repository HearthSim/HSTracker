//
//  MulliganGuideStatusData.swift
//  HSTracker
//
//  Created by Francisco Moraes on 2/19/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

struct MulliganGuideStatusData: Decodable {
    
    enum Status: String {
        case NO_DATA,
            READY
    }
    
    struct Deck: Decodable {
        var status: String
    }
    
    var decks: [String: Deck]
}
