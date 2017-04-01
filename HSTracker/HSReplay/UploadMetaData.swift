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

    static func generate(game: InternalGameStats?) -> UploadMetaData {
        let metaData = UploadMetaData()

        let playerInfo = getPlayerInfo(game: game)
        if let _playerInfo = playerInfo {
            metaData.player1 = _playerInfo.player1
            metaData.player2 = _playerInfo.player2
        }

        if let serverInfo = game?.serverInfo {
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

        if let game = game {
            if game.startTime > Date.distantPast {
                metaData.matchStart = UploadMetaData.iso8601StringFormatter.string(from: game.startTime)
            }

            metaData.gameType = game.gameType != .gt_unknown
                ? BnetGameType.getBnetGameType(gameType: game.gameType,
                                               format: game.format).rawValue
                : BnetGameType.getGameType(mode: game.gameMode,
                                           format: game.format).rawValue

            if let format = game.format {
                metaData.format = format.toFormatType().rawValue
            }

            if game.brawlSeasonId > 0 {
                metaData.brawlSeason = game.brawlSeasonId
            }
            if game.rankedSeasonId > 0 {
                metaData.ladderSeason = game.rankedSeasonId
            }

        }

        metaData.spectatorMode = game?.gameMode == .spectator
        //metaData.reconnected = gameMetaData?.reconnected ?? false
        metaData.resumable = game?.serverInfo?.resumable ?? false

        var friendlyPlayerId: Int? = nil
        if let _friendlyPlayerId = game?.friendlyPlayerId,
            _friendlyPlayerId > 0 {
            friendlyPlayerId = _friendlyPlayerId
        } else if let _playerFriendlyPlayerId = playerInfo?.friendlyPlayerId,
            _playerFriendlyPlayerId > 0 {
            friendlyPlayerId = _playerFriendlyPlayerId
        }
        metaData.friendlyPlayerId = friendlyPlayerId

        let scenarioId = game?.serverInfo?.mission ?? 0
        if scenarioId > 0 {
            metaData.scenarioId = scenarioId
        }

        var build: Int? = nil
        if let _build = game?.hearthstoneBuild {
            build = _build
        } else if let game = game {
            build = BuildDates.get(byDate: game.startTime)?.build
        }
        if let _build = build, _build > 0 {
            metaData.hearthstoneBuild = _build
        }

        return metaData
    }

    static func getPlayerInfo(game: InternalGameStats?) -> PlayerInfo? {
        guard let game = game else { return nil }

        if game.friendlyPlayerId == 0 {
            return nil
        }

        let friendly = Player()
        let opposing = Player()

        if game.rank > 0 {
            friendly.rank = game.rank
        }
        if game.legendRank > 0 {
            friendly.legendRank = game.legendRank
        }
        if game.playerCardbackId > 0 {
            friendly.cardBack = game.playerCardbackId
        }
        if game.stars > 0 {
            friendly.stars = game.stars
        }

        if let hsDeckId = game.hsDeckId, hsDeckId > 0 {
            friendly.deckId = hsDeckId
        }

        if game.gameMode == .arena {
            if game.arenaWins > 0 {
                friendly.wins = game.arenaWins
            }
            if game.arenaLosses > 0 {
                friendly.losses = game.arenaLosses
            }
        } else if game.gameMode == .brawl {
            if game.brawlWins > 0 {
                friendly.wins = game.brawlWins
            }
            if game.brawlLosses > 0 {
                friendly.losses = game.brawlLosses
            }
        }

        if game.opponentRank > 0 {
            opposing.rank = game.opponentRank
        }
        if game.opponentLegendRank > 0 {
            opposing.legendRank = game.opponentLegendRank
        }
        if game.opponentCardbackId > 0 {
            opposing.cardBack = game.opponentCardbackId
        }

        return PlayerInfo(player1: game.friendlyPlayerId == 1 ? friendly : opposing,
                          player2: game.friendlyPlayerId == 2 ? friendly : opposing)
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

