//
//  UploadMetaData.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 12/08/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import Wrap

class UploadMetaData {
    private var statistic: InternalGameStats?
    private var game: Game?
    private var log: [String] = []
    var dateStart: Date?
    
    var serverIp: String?
    var serverPort: String?
    var gameHandle: String?
    var clientHandle: String?
    var reconnected: String?
    var resumable: Bool?
    var spectatePassword: String?
    var auroraPassword: String?
    var serverVersion: String?
    var matchStart: String?
    var hearthstoneBuild: Int?
    var gameType: Int?
    var spectatorMode: Bool?
    var _friendlyPlayerId: Int?
    var friendlyPlayerId: Int?
    var ladderSeason: Int?
    var brawlSeason: Int?
    var scenarioId: Int?
    var format: Int?
    var player1: Player = Player()
    var player2: Player = Player()
    
    public static let iso8601StringFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        return formatter
    }()

	static func generate(stats: InternalGameStats, deck: PlayingDeck?) -> (UploadMetaData, String) {
        let metaData = UploadMetaData()

		let playerInfo = getPlayerInfo(stats: stats, deck: deck)
        if let _playerInfo = playerInfo {
            metaData.player1 = _playerInfo.player1
            metaData.player2 = _playerInfo.player2
        }

        if let serverInfo = stats.serverInfo {
            if !serverInfo.address.isBlank {
                metaData.serverIp = serverInfo.address
            }
            if serverInfo.port > 0 {
				metaData.serverPort = "\(serverInfo.port)"
            }
            if serverInfo.gameHandle > 0 {
				metaData.gameHandle = "\(serverInfo.gameHandle)"
            }
            if serverInfo.clientHandle > 0 {
				metaData.clientHandle = "\(serverInfo.clientHandle)"
            }

            if !serverInfo.spectatorPassword.isBlank {
				metaData.spectatePassword = serverInfo.spectatorPassword
            }
            if !serverInfo.auroraPassword.isBlank {
				metaData.auroraPassword = serverInfo.auroraPassword
            }
            if !serverInfo.version.isBlank {
				metaData.serverVersion = serverInfo.version
            }
        }
        
        if stats.startTime > Date.distantPast {
            metaData.matchStart = UploadMetaData.iso8601StringFormatter.string(from: stats.startTime)
        }
        
        metaData.gameType = stats.gameType != .gt_unknown
            ? BnetGameType.getBnetGameType(gameType: stats.gameType,
                                           format: stats.format).rawValue
            : BnetGameType.getGameType(mode: stats.gameMode,
                                       format: stats.format).rawValue
        
        if let format = stats.format {
            metaData.format = format.toFormatType().rawValue
        }
        
        if stats.brawlSeasonId > 0 {
            metaData.brawlSeason = stats.brawlSeasonId
        }
        if stats.rankedSeasonId > 0 {
            metaData.ladderSeason = stats.rankedSeasonId
        }

        metaData.spectatorMode = stats.gameMode == .spectator
        //metaData.reconnected = gameMetaData?.reconnected ?? false
        metaData.resumable = stats.serverInfo?.resumable ?? false

        var friendlyPlayerId: Int? = nil
        if stats.friendlyPlayerId > 0 {
            friendlyPlayerId = stats.friendlyPlayerId
        } else if let _playerFriendlyPlayerId = playerInfo?.friendlyPlayerId,
            _playerFriendlyPlayerId > 0 {
            friendlyPlayerId = _playerFriendlyPlayerId
        }
        metaData.friendlyPlayerId = friendlyPlayerId

        let scenarioId = stats.serverInfo?.mission ?? 0
        if scenarioId > 0 {
            metaData.scenarioId = scenarioId
        }

        var build: Int? = nil
        if let _build = stats.hearthstoneBuild {
            build = _build
        } else {
            build = BuildDates.get(byDate: stats.startTime)?.build
        }
        if let _build = build, _build > 0 {
            metaData.hearthstoneBuild = _build
        }

        return (metaData, stats.statId)
    }

    static func getPlayerInfo(stats: InternalGameStats, deck: PlayingDeck?) -> PlayerInfo? {

        if stats.friendlyPlayerId == 0 {
            return nil
        }

        let friendly = Player()
        let opposing = Player()
		
		if let deck = deck {
			friendly.add(deck: deck)
		}

        if stats.rank > 0 {
            friendly.rank = stats.rank
        }
        if stats.legendRank > 0 {
            friendly.legendRank = stats.legendRank
        }
        if stats.playerCardbackId > 0 {
            friendly.cardBack = stats.playerCardbackId
        }
        if stats.stars > 0 {
            friendly.stars = stats.stars
        }

        if let hsDeckId = stats.hsDeckId, hsDeckId > 0 {
            friendly.deckId = hsDeckId
        }

        if stats.gameMode == .arena {
            if stats.arenaWins > 0 {
                friendly.wins = stats.arenaWins
            }
            if stats.arenaLosses > 0 {
                friendly.losses = stats.arenaLosses
            }
        } else if stats.gameMode == .brawl {
            if stats.brawlWins > 0 {
                friendly.wins = stats.brawlWins
            }
            if stats.brawlLosses > 0 {
                friendly.losses = stats.brawlLosses
            }
        }

        if stats.opponentRank > 0 {
            opposing.rank = stats.opponentRank
        }
        if stats.opponentLegendRank > 0 {
            opposing.legendRank = stats.opponentLegendRank
        }
        if stats.opponentCardbackId > 0 {
            opposing.cardBack = stats.opponentCardbackId
        }

        return PlayerInfo(player1: stats.friendlyPlayerId == 1 ? friendly : opposing,
                          player2: stats.friendlyPlayerId == 2 ? friendly : opposing)
    }

    class Player {
        var rank: Int?
        var legendRank: Int?
        var stars: Int?
        var wins: Int?
        var losses: Int?
        var deck: [String]?
        var deckId: Int64?
        var cardBack: Int?
		
		func add(deck: PlayingDeck) {
			var cards = [String]()
			for card in deck.cards {
				for _ in 0 ..< card.count {
					cards.append(card.id)
				}
			}
			self.deck = cards
		}
    }

    struct PlayerInfo {
        let player1: Player
        let player2: Player
        let friendlyPlayerId: Int

        init(player1: Player, player2: Player, friendlyPlayerId: Int = -1) {
            self.player1 = player1
            self.player2 = player2
            self.friendlyPlayerId = friendlyPlayerId
        }
    }
}
extension UploadMetaData.Player: WrapCustomizable {
    func keyForWrapping(propertyNamed propertyName: String) -> String? {
        switch propertyName {
        case "legendRank": return "legend_rank"
        case "deckId": return "deck_id"
        case "cardBack": return "cardback"
        default: break
        }
        
        return propertyName
    }
}
extension UploadMetaData: WrapCustomizable {
    func keyForWrapping(propertyNamed propertyName: String) -> String? {
        switch propertyName {
        case "serverIp": return "server_ip"
        case "serverPort": return "server_port"
        case "gameHandle": return "game_handle"
        case "clientHandle": return "client_handle"
        case "reconnected": return "reconnecting"
        case "spectatePassword": return "spectator_password"
        case "auroraPassword": return "aurora_password"
        case "serverVersion": return "server_version"
        case "matchStart": return "match_start"
        case "hearthstoneBuild": return "build"
        case "gameType": return "game_type"
        case "spectatorMode": return "spectator_mode"
        case "friendlyPlayerId": return "friendly_player"
        case "scenarioId": return "scenario_id"
        case "ladderSeason": return "ladder_season"
        case "brawlSeason": return "brawl_season"
        case "statistic", "game",
             "log", "gameStart":
            return nil
        default: break
        }
        
        return propertyName
    }
}

