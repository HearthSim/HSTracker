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
    }

    var localPlayer: Player
    var opposingPlayer: Player
    var brawlSeasonId: Int
    var missionId: Int
    var rankedSeasonId: Int

    init(info: MirrorMatchInfo) {
        localPlayer = Player(name: info.localPlayer.name,
                             playerId: info.localPlayer.playerId as Int,
                             standardRank: info.localPlayer.standardRank as Int,
                             standardLegendRank: info.localPlayer.standardLegendRank as Int,
                             standardStars: info.localPlayer.standardStars as Int,
                             wildRank: info.localPlayer.wildRank as Int,
                             wildLegendRank: info.localPlayer.wildLegendRank as Int,
                             wildStars: info.localPlayer.wildStars as Int,
                             cardBackId: info.localPlayer.cardBackId as Int)

        opposingPlayer = Player(name: info.opposingPlayer.name,
                                playerId: info.opposingPlayer.playerId as Int,
                                standardRank: info.opposingPlayer.standardRank as Int,
                                standardLegendRank: info.opposingPlayer.standardLegendRank as Int,
                                standardStars: info.opposingPlayer.standardStars as Int,
                                wildRank: info.opposingPlayer.wildRank as Int,
                                wildLegendRank: info.opposingPlayer.wildLegendRank as Int,
                                wildStars: info.opposingPlayer.wildStars as Int,
                                cardBackId: info.opposingPlayer.cardBackId as Int)

        brawlSeasonId = info.brawlSeasonId as Int
        missionId = info.missionId as Int
        rankedSeasonId = info.rankedSeasonId as Int
    }
}
