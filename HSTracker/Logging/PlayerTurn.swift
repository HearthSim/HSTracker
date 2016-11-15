//
//  PlayerTurn.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 15/10/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation

struct PlayerTurn {
    let player: PlayerType
    let turn: Int
}

extension PlayerTurn: Hashable {
    var hashValue: Int {
        return player.rawValue.hashValue ^ turn.hashValue
    }

    static func == (lhs: PlayerTurn, rhs: PlayerTurn) -> Bool {
        return lhs.player == rhs.player && lhs.turn == rhs.turn
    }
}
