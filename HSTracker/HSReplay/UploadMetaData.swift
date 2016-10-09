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
    private var statistic: Statistic?
    private var game: Game?
    private var log: [String]
    var dateStart: NSDate?
    
    var serverIp: String?
    var serverPort: String?
    var gameHandle: String?
    var clientHandle: String?
    var reconnected: String?
    var resumable: String?
    var spectatePassword: String?
    var auroraPassword: String?
    var serverVersion: String?
    var matchStart: String?
    var hearthstoneBuild: Int?
    var gameType: Int?
    var spectatorMode: Bool?
    var _friendlyPlayerId: Int?
    var friendlyPlayerId: Int?

    var scenarioId: Int?
    var format: Int?
    var player1: Player = Player()
    var player2: Player = Player()
    
    init(log: [String], game: Game?, statistic: Statistic?, gameStart: NSDate? = nil) {
        self.log = log
        self.game = game
        self.statistic = statistic
        fillPlayerData()

        self.friendlyPlayerId = self.game?.player.id ?? 0 > 0 ? self.game?.player.id ?? nil
            : (self._friendlyPlayerId > 0 ? self._friendlyPlayerId : nil)

        if let _date = statistic?.date {
            dateStart = _date
        } else if let _date = gameStart {
            dateStart = _date
        }
        
        if let date = dateStart {
            self.matchStart = date.toIso8601String()
        }
    }

    private func fillPlayerData() {
        let friendly = Player()
        let opposing = Player()
        
        if let statistic = statistic {
            if statistic.playerRank > 0 {
                friendly.rank = statistic.playerRank
            }
            if let legendRank = statistic.legendRank where legendRank > 0 {
                friendly.legendRank = legendRank
            }
            if let opponentLegendRank = statistic.opponentLegendRank where opponentLegendRank > 0 {
                opposing.legendRank = opponentLegendRank
            }
            if let opponentRank = statistic.opponentRank where opponentRank > 0 {
                opposing.rank = opponentRank
            }
        }

        if let game = game {
            if game.player.id > 0 {
                player1 = game.player.id == 1 ? friendly : opposing
                player2 = game.player.id == 2 ? friendly : opposing
            } else {
                let player1Name = getPlayer1Name()
                if player1Name == game.player.name {
                    _friendlyPlayerId = 1
                    player1 = friendly
                    player2 = opposing
                } else {
                    _friendlyPlayerId = 2
                    player1 = opposing
                    player2 = friendly
                }
            }
        }
    }
    
    private func getPlayer1Name() -> String? {
        let regex = "TAG_CHANGE Entity=(.+) tag=CONTROLLER value=1"
        for line in log {
            if line.match(regex) {
                let matches = line.matches(regex)
                return matches[0].value
            }
        }
        return nil
    }
    
    class Player {
        var rank: Int?
        var legendRank: Int?
        var stars: Int?
        var wins: Int?
        var losses: Int?
        var deck: [String]?
        var deckId: Int?
        var cardBack: Int?
    }
}
extension UploadMetaData.Player: WrapCustomizable {
    func keyForWrappingPropertyNamed(propertyName: String) -> String? {
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
    func keyForWrappingPropertyNamed(propertyName: String) -> String? {
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
        case "statistic", "game",
             "log", "gameStart":
            return nil
        default: break
        }
        
        return propertyName
    }
}

