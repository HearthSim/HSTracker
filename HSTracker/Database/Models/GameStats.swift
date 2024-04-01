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
    var rank = 0
    var opponentRank = 0
    var leagueId = 0
    var starLevel = 0
    var starLevelAfter = 0
    var starMultiplier = 0
    var stars = 0
    var starsAfter = 0
    var opponentStarLevel = 0
    var legendRank = 0
    var legendRankAfter = 0
    var opponentLegendRank = 0
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
    var battlegroundsRatingAfter = 0
    var battlegroundsRaces: [Int] = []
    var mercenariesRating = 0
    var mercenariesRatingAfter = 0
    var mercenariesBountyRunId = ""
    var mercenariesBountyRunTurnsTaken = 0
    var mercenariesBountyRunCompletedNodes = 0
    var mercenariesBountyRunRewards: [MercenaryCoinsEntry]?
    var playerCards = [TrackedCard]()
    var opponentCards = [TrackedCard]()
    var sideboards = [Sideboard]()
    var opponentHeroCardId: String?
    var deckId = ""
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
    var revealedCards: [Card] = []
    
    var isDungeonMatch: Bool {
        return gameType == .gt_vs_ai && DefaultDecks.DungeonRun.isDungeonBoss(opponentHeroCardId)
    }
    var isPVPDungeonMatch: Bool {
        return gameType == .gt_pvpdr || gameType == .gt_pvpdr_paid
    }
    
    func setPlayerCards(_ deck: PlayingDeck?, _ revealedCards: [Card]) {
        setPlayerCards(deck?.cards, revealedCards)
    }
    
    func setPlayerCards(_ deck: [Card]?, _ revealedCards: [Card]) {
        playerCards.removeAll()
        for c in revealedCards {
            let card = playerCards.first { x in x.id == c.id }
            if let card {
                card.count += 1
            } else {
                playerCards.append(TrackedCard(c.id, c.count))
            }
        }
        if let deck {
            for c in deck {
                let e = playerCards.first { x in x.id == c.id }
                if e == nil {
                    playerCards.append(TrackedCard(c.id, c.count, c.count))
                } else if let e, c.count > e.count {
                    e.unconfirmed = c.count - e.count
                    e.count = c.count
                }
            }
        }
    }
    
    func setOpponentCards(_ revealedCards: [Card]) {
        opponentCards.removeAll()
        for c in revealedCards {
            if let card = opponentCards.first(where: { x in x.id == c.id }) {
                card.count += 1
            } else {
                opponentCards.append(TrackedCard(c.id, c.count))
            }
        }
    }
    
    func setPlayerSideboards(_ sideboards: [Sideboard]) {
        self.sideboards = sideboards
    }

    func toGameStats() -> GameStats {
        let gameStats = GameStats()
        gameStats.statId = statId
        gameStats.hearthstoneBuild.value = hearthstoneBuild
        gameStats.playerCardbackId = playerCardbackId
        gameStats.opponentCardbackId = opponentCardbackId
        gameStats.opponentHero = opponentHero
        gameStats.friendlyPlayerId = friendlyPlayerId
        gameStats.opponentName = opponentName
        gameStats.opponentLegendRank = opponentLegendRank
        gameStats.playerName = playerName
        gameStats.legendRank = legendRank
        gameStats.stars = stars
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
        for c in opponentCards {
            if let id = c.id {
                let card = RealmCard(id: id, count: c.count)
                gameStats.opponentCards.append(card)
            }
        }
        for c in revealedCards {
            let card = RealmCard(id: c.id, count: c.count)
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
    var hearthstoneBuild = RealmProperty<Int?>()
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

    var hsDeckId = RealmProperty<Int64?>()
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
