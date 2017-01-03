//
//  GameStats.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 29/12/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation

class GameStats {
    var playerHero: CardClass = .neutral
    var opponentHero: CardClass = .neutral
    var coin = false
    var gameMode: GameMode = .none
    var result: GameResult = .unknow
    var turns = -1
    var startTime = Date()
    var endTime = Date()
    var note = ""
    var playerName = ""
    var opponentName = ""
    var wasConceded = false
    var rank = -1
    var stars = -1
    var legendRank = -1
    var opponentLegendRank = -1
    var opponentRank = -1
    var hearthstoneBuild: Int?
    var playerCardbackId = -1
    var opponentCardbackId = -1
    var friendlyPlayerId = -1
    var scenarioId = -1
    var serverInfo: ServerInfo?
    var gameType: GameType = .gt_unknown
    var hsDeckId: Int64?
    var brawlSeasonId = -1
    var rankedSeasonId = -1
    var arenaWins = 0
    var arenaLosses = 0
    var brawlWins = 0
    var brawlLosses = 0
    private var _format: Format?
    var format: Format? {
        get {
            return gameMode == .ranked || gameMode == .casual ? _format : nil
        }
        set {
            _format = newValue
        }
    }

    init() {
        if let build = BuildDates.latestBuild {
            hearthstoneBuild = build.build
        }
    }
}

extension GameStats: CustomStringConvertible {
    var description: String {
        return "playerHero: \(playerHero), " +
        "opponentHero: \(opponentHero), " +
        "hsDeckId: \(hsDeckId), " +
        "coin: \(coin), " +
        "gameMode: \(gameMode), " +
        "result: \(result), " +
        "turns: \(turns), " +
        "startTime: \(startTime), " +
        "endTime: \(endTime), " +
        "note: \(note), " +
        "playerName: \(playerName), " +
        "opponentName: \(opponentName), " +
        "wasConceded: \(wasConceded), " +
        "rank: \(rank), " +
        "stars: \(stars), " +
        "legendRank: \(legendRank), " +
        "opponentLegendRank: \(opponentLegendRank), " +
        "opponentRank: \(opponentRank), " +
        "hearthstoneBuild: \(hearthstoneBuild), " +
        "playerCardbackId: \(playerCardbackId), " +
        "opponentCardbackId: \(opponentCardbackId), " +
        "friendlyPlayerId: \(friendlyPlayerId), " +
        "scenarioId: \(scenarioId), " +
        "gameType: \(gameType), " +
        "brawlSeasonId: \(brawlSeasonId), " +
        "rankedSeasonId: \(rankedSeasonId), " +
        "arenaWins: \(arenaWins), " + 
        "arenaLosses: \(arenaLosses), " + 
        "brawlWins: \(brawlWins), " + 
        "brawlLosses: \(brawlLosses), " + 
        "format: \(format), " +
        "serverInfo: \(serverInfo)"
    }
}
