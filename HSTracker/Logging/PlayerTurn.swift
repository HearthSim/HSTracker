//
//  PlayerTurn.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 15/10/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation

struct PlayerTurn: Equatable, Hashable {
    let player: PlayerType
    let turn: Int
}
