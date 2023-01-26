//
//  Tier7Trial.swift
//  HSTracker
//
//  Created by Francisco Moraes on 12/9/22.
//  Copyright © 2022 Benjamin Michotte. All rights reserved.
//

import Foundation

struct Tier7TrialStatus: Decodable {
    var trials_remaining: Int
    var hours_til_next_reset: Int?
}

struct Tier7TrialActivation: Decodable {
    var msg: String
}
