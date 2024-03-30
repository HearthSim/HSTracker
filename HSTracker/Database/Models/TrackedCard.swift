//
//  TrackedCard.swift
//  HSTracker
//
//  Created by Francisco Moraes on 3/29/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class TrackedCard {
    var id: String?
    var count: Int
    var unconfirmed: Int
    
    init() {
        self.count = 0
        self.unconfirmed = 0
    }
    
    init(_ id: String, _ count: Int, _ unconfirmed: Int = 0) {
        self.id = id
        self.count = count
        self.unconfirmed = unconfirmed
    }
}
