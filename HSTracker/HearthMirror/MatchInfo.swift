//
//  MatchInfo.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 30/12/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import HearthMirror

struct MatchInfo {
    struct AccountId {
        var hi: Int64
        var lo: Int64
    }
    struct MedalInfo {
        var leagueId: Int
        var stars: Int
        var legendRank: Int
        var starsPerWin: Int
        var starLevel: Int
        
        init(mirrorMedalInfo: MirrorMedalInfo) {
            self.leagueId = mirrorMedalInfo.leagueId as? Int ?? 0
            self.legendRank = mirrorMedalInfo.legendRank as? Int ?? 0
            self.stars = mirrorMedalInfo.stars as? Int ?? 0
            self.starsPerWin = mirrorMedalInfo.starsPerWin as? Int ?? 0
            self.starLevel = mirrorMedalInfo.starLevel as? Int ?? 0
        }
    }
    struct Player {
        var name: String
        var playerId: Int
        var accountId: AccountId
        var battleTag: String?
        var wildMedalInfo: MedalInfo
        var standardMedalInfo: MedalInfo
        var classicMedalInfo: MedalInfo
        var twistMedalInfo: MedalInfo
        var cardBackId: Int
        var standardRank: Int
        var wildRank: Int
        var classicRank: Int
        var twistRank: Int

        init(player: MirrorPlayer) {
            self.name = player.name
            self.playerId = player.playerId as? Int ?? 0
            self.cardBackId = player.cardBackId as? Int ?? 0
            self.accountId = AccountId(hi: player.accountId.hi.int64Value, lo: player.accountId.lo.int64Value)
            if let btag = player.battleTag {
                self.battleTag = "\(btag.name)#\(btag.number)"
            }
            self.standardMedalInfo = MedalInfo(mirrorMedalInfo: player.standardMedalInfo)
            self.wildMedalInfo = MedalInfo(mirrorMedalInfo: player.wildMedalInfo)
            self.classicMedalInfo = MedalInfo(mirrorMedalInfo: player.classicMedalInfo)
            self.twistMedalInfo = MedalInfo(mirrorMedalInfo: player.twistMedalInfo)
            
            self.standardRank = player.standardRank.intValue
            self.wildRank = player.wildRank.intValue
            self.classicRank = player.classicRank.intValue
            self.twistRank = player.twistRank.intValue
        }
    }

    var localPlayer: Player
    var opposingPlayer: Player
    var brawlSeasonId: Int
    var missionId: Int
    var rankedSeasonId: Int
    var gameType: GameType
    var format: Format
    var formatType: FormatType
    var spectator: Bool

    init(info: MirrorMatchInfo) {
        localPlayer = Player(player: info.localPlayer)
        opposingPlayer = Player(player: info.opposingPlayer)

        brawlSeasonId = info.brawlSeasonId as? Int ?? 0
        missionId = info.missionId as? Int ?? 0
        rankedSeasonId = info.rankedSeasonId as? Int ?? 0
        gameType = GameType(rawValue: info.gameType as? Int ?? 0) ?? .gt_unknown
        formatType = FormatType(rawValue: info.formatType as? Int ?? 0) ?? .ft_unknown
        format = Format(formatType: formatType)
        spectator = info.spectator
    }
}
