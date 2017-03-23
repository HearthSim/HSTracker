//
//  BrawlInfo.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 3/01/17.
//  Copyright © 2017 Benjamin Michotte. All rights reserved.
//

import Foundation
import HearthMirror

struct BrawlInfo {
    let maxWins: Int?
    let maxLosses: Int?
    let isSessionBased: Bool
    let wins: Int
    let losses: Int
    let gamesPlayed: Int
    let winStreak: Int

    init(info: MirrorBrawlInfo) {
        maxWins = info.maxWins as? Int
        maxLosses = info.maxLosses as? Int
        isSessionBased = info.isSessionBased
        wins = info.wins as Int
        losses = info.losses as Int
        gamesPlayed = info.gamesPlayed as Int
        winStreak = info.winStreak as Int
    }
}
