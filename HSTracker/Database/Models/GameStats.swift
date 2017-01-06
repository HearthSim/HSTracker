//
//  GameStats.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 29/12/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import RealmSwift

class GameStats: Object {
    dynamic var statId: String = generateId()

    override static func primaryKey() -> String? {
        return "statId"
    }

    private dynamic var _playerHero = CardClass.neutral.rawValue
    var playerHero: CardClass {
        get { return CardClass(rawValue: _playerHero)! }
        set { _playerHero = newValue.rawValue }
    }

    private dynamic var _opponentHero = CardClass.neutral.rawValue
    var opponentHero: CardClass {
        get { return CardClass(rawValue: _opponentHero)! }
        set { _opponentHero = newValue.rawValue }
    }

    dynamic var coin = false

    private dynamic var _gameMode = GameMode.none.rawValue
    var gameMode: GameMode {
        get { return GameMode(rawValue: _gameMode)! }
        set { _gameMode = newValue.rawValue }
    }

    private dynamic var _result = GameResult.unknow.rawValue
    var result: GameResult {
        get { return GameResult(rawValue: _result)! }
        set { _result = newValue.rawValue }
    }

    dynamic var turns = -1
    dynamic var startTime = Date()
    dynamic var endTime = Date()
    dynamic var note = ""
    dynamic var playerName = ""
    dynamic var opponentName = ""
    dynamic var wasConceded = false
    dynamic var rank = -1
    dynamic var stars = -1
    dynamic var legendRank = -1
    dynamic var opponentLegendRank = -1
    dynamic var opponentRank = -1
    var hearthstoneBuild = RealmOptional<Int>()
    dynamic var playerCardbackId = -1
    dynamic var opponentCardbackId = -1
    dynamic var friendlyPlayerId = -1
    dynamic var scenarioId = -1
    dynamic var serverInfo: ServerInfo?

    dynamic var season = 0

    private dynamic var _gameType = GameType.gt_unknown.rawValue
    var gameType: GameType {
        get { return GameType(rawValue: _gameType)! }
        set { _gameType = newValue.rawValue }
    }

    var hsDeckId = RealmOptional<Int64>()
    dynamic var brawlSeasonId = -1
    dynamic var rankedSeasonId = -1
    dynamic var arenaWins = 0
    dynamic var arenaLosses = 0
    dynamic var brawlWins = 0
    dynamic var brawlLosses = 0

    dynamic var __format: String? = nil
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

    dynamic var hsReplayId: String? = nil
    let opponentCards = List<RealmCard>()
    let revealedCards = List<RealmCard>()

    let deck = LinkingObjects(fromType: Deck.self, property: "gameStats")
}
