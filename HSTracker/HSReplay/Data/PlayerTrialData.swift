//
//  Tier7Trial.swift
//  HSTracker
//
//  Created by Francisco Moraes on 12/9/22.
//  Copyright © 2022 Benjamin Michotte. All rights reserved.
//

import Foundation

struct PlayerTrialStatus: Decodable {
    var trials_remaining: Int
    var hours_til_next_reset: Int?
}

struct PlayerTrialActivation: Decodable {
    var trials_remaining: Int
    var hours_til_next_reset: Int?
    var token: String
}
