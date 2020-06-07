//
//  GameStats.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 29/12/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import RealmSwift

class InternalGameStats {
    var statId: String = generateId()
    var playerHero: CardClass = .neutral
    var opponentHero: CardClass = .neutral
    var coin = false
    var gameMode: GameMode = .none
    var result: GameResult = .unknown
    var turns = -1
    var startTime = Date()
    var endTime = Date()
    var note = ""
    var playerName = ""
    var opponentName = ""
    var wasConceded = false
    var playerMedalInfo: MatchInfo.MedalInfo?
    var opponentMedalInfo: MatchInfo.MedalInfo?
    var hearthstoneBuild: Int?
    var playerCardbackId = -1
    var opponentCardbackId = -1
    var friendlyPlayerId = -1
    var opposingPlayerId = -1
    var scenarioId = -1
    var serverInfo: ServerInfo?
    var season = 0
    var gameType: GameType = .gt_unknown
    var hsDeckId: Int64?
    var brawlSeasonId = -1
    var rankedSeasonId = -1
    var arenaWins = 0
    var arenaLosses = 0
    var brawlWins = 0
    var brawlLosses = 0
    var battlegroundsRating = 0
    private var _format: Format?
        
    var format: Format? {
        get {
            return gameMode == .ranked || gameMode == .casual ? _format : nil
        }
        set {
            _format = newValue
        }
    }
    var hsReplayId: String?
    var opponentCards: [Card] = []
    var revealedCards: [Card] = []

    func toGameStats() -> GameStats {
        let gameStats = GameStats()
        gameStats.statId = statId
        gameStats.hearthstoneBuild.value = hearthstoneBuild
        gameStats.playerCardbackId = playerCardbackId
        gameStats.opponentCardbackId = opponentCardbackId
        gameStats.opponentHero = opponentHero
        gameStats.friendlyPlayerId = friendlyPlayerId
        gameStats.opponentName = opponentName
        gameStats.opponentLegendRank = opponentMedalInfo?.legendRank ?? 0
        gameStats.playerName = playerName
        gameStats.legendRank = playerMedalInfo?.legendRank ?? 0
        gameStats.stars = playerMedalInfo?.stars ?? 0
        gameStats.wasConceded = wasConceded
        gameStats.turns = turns
        gameStats.scenarioId = scenarioId
        gameStats.serverInfo = serverInfo
        gameStats.season = season
        gameStats.gameMode = gameMode
        gameStats.gameType = gameType
        gameStats.hsDeckId.value = hsDeckId
        gameStats.brawlSeasonId = brawlSeasonId
        gameStats.rankedSeasonId = rankedSeasonId
        gameStats.arenaWins = arenaWins
        gameStats.arenaLosses = arenaLosses
        gameStats.brawlWins = brawlWins
        gameStats.brawlLosses = brawlLosses
        gameStats.format = format
        gameStats.hsReplayId = hsReplayId
        gameStats.result = result
        opponentCards.forEach {
            let card = RealmCard(id: $0.id, count: $0.count)
            gameStats.opponentCards.append(card)
        }
        revealedCards.forEach {
            let card = RealmCard(id: $0.id, count: $0.count)
            gameStats.revealedCards.append(card)
        }
        return gameStats
    }
}

extension InternalGameStats: CustomStringConvertible {
    var description: String {
        return "playerHero: \(playerHero), " +
            "opponentHero: \(opponentHero), " +
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
            "hearthstoneBuild: \(String(describing: hearthstoneBuild)), " +
            "playerCardbackId: \(playerCardbackId), " +
            "opponentCardbackId: \(opponentCardbackId), " +
            "friendlyPlayerId: \(friendlyPlayerId), " +
            "scenarioId: \(scenarioId), " +
            "serverInfo: \(String(describing: serverInfo)), " +
            "season: \(season), " +
            "gameType: \(gameType), " +
            "hsDeckId: \(String(describing: hsDeckId)), " +
            "brawlSeasonId: \(brawlSeasonId), " +
            "rankedSeasonId: \(rankedSeasonId), " +
            "arenaWins: \(arenaWins), " +
            "arenaLosses: \(arenaLosses), " +
            "brawlWins: \(brawlWins), " +
            "brawlLosses: \(brawlLosses), " +
            "format: \(String(describing: format)), " +
            "hsReplayId: \(String(describing: hsReplayId)), " +
            "opponentCards: \(opponentCards), " +
            "revealedCards: \(revealedCards)"
    }
}

class GameStats: Object {
    @objc dynamic var statId = ""

    override static func primaryKey() -> String? {
        return "statId"
    }

    @objc private dynamic var _playerHero = CardClass.neutral.rawValue
    var playerHero: CardClass {
        get { return CardClass(rawValue: _playerHero)! }
        set { _playerHero = newValue.rawValue }
    }

    @objc private dynamic var _opponentHero = CardClass.neutral.rawValue
    var opponentHero: CardClass {
        get { return CardClass(rawValue: _opponentHero)! }
        set { _opponentHero = newValue.rawValue }
    }

    @objc dynamic var coin = false

    @objc private dynamic var _gameMode = GameMode.none.rawValue
    var gameMode: GameMode {
        get { return GameMode(rawValue: _gameMode)! }
        set { _gameMode = newValue.rawValue }
    }

    @objc private dynamic var _result = GameResult.unknown.rawValue
    var result: GameResult {
        get { return GameResult(rawValue: _result)! }
        set { _result = newValue.rawValue }
    }

    @objc dynamic var turns = -1
    @objc dynamic var startTime = Date()
    @objc dynamic var endTime = Date()
    @objc dynamic var note = ""
    @objc dynamic var playerName = ""
    @objc dynamic var opponentName = ""
    @objc dynamic var wasConceded = false
    @objc dynamic var rank = -1
    @objc dynamic var stars = -1
    @objc dynamic var legendRank = -1
    @objc dynamic var opponentLegendRank = -1
    @objc dynamic var opponentRank = -1
    var hearthstoneBuild = RealmOptional<Int>()
    @objc dynamic var playerCardbackId = -1
    @objc dynamic var opponentCardbackId = -1
    @objc dynamic var friendlyPlayerId = -1
    @objc dynamic var scenarioId = -1
    @objc dynamic var serverInfo: ServerInfo?

    @objc dynamic var season = 0

    @objc private dynamic var _gameType = GameType.gt_unknown.rawValue
    var gameType: GameType {
        get { return GameType(rawValue: _gameType)! }
        set { _gameType = newValue.rawValue }
    }

    var hsDeckId = RealmOptional<Int64>()
    @objc dynamic var brawlSeasonId = -1
    @objc dynamic var rankedSeasonId = -1
    @objc dynamic var arenaWins = 0
    @objc dynamic var arenaLosses = 0
    @objc dynamic var brawlWins = 0
    @objc dynamic var brawlLosses = 0

    @objc dynamic var __format: String?
    private var _format: Format? {
        get {
            if let __format = __format {
                return Format(rawValue: __format)
            }
            return nil
        }
        set { __format = newValue?.rawValue ?? nil }
    }
    var format: Format? {
        get {
            return gameMode == .ranked || gameMode == .casual ? _format : nil
        }
        set {
            _format = newValue
        }
    }

    @objc dynamic var hsReplayId: String?
    let opponentCards = List<RealmCard>()
    let revealedCards = List<RealmCard>()

    let deck = LinkingObjects(fromType: Deck.self, property: "gameStats")
}
