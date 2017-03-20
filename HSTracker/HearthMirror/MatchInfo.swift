//
//  MatchInfo.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 30/12/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation

struct MatchInfo {
    struct Player {
        var name: String
        var playerId: Int
        var standardRank: Int
        var standardLegendRank: Int
        var standardStars: Int
        var wildRank: Int
        var wildLegendRank: Int
        var wildStars: Int
        var cardBackId: Int

        init(player: MirrorPlayer) {
            self.name = player.name
            self.playerId = player.playerId as Int
            self.standardRank = player.standardRank as Int
            self.standardLegendRank = player.standardLegendRank as Int
            self.standardStars = player.standardStars as Int
            self.wildRank = player.wildRank as Int
            self.wildLegendRank = player.wildLegendRank as Int
            self.wildStars = player.wildStars as Int
            self.cardBackId = player.cardBackId as Int
        }
    }

    var localPlayer: Player
    var opposingPlayer: Player
    var brawlSeasonId: Int
    var missionId: Int
    var rankedSeasonId: Int

    init(info: MirrorMatchInfo) {
        localPlayer = Player(player: info.localPlayer)
        opposingPlayer = Player(player: info.opposingPlayer)

        brawlSeasonId = info.brawlSeasonId as Int
        missionId = info.missionId as Int
        rankedSeasonId = info.rankedSeasonId as Int
    }
}
