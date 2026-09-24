//
//  GameInfoHandler.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/5/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class GameInfoHandler: LogEventParser {
    let PlayerRegex = Regex("PlayerID=(\\d+), PlayerName=(.+)")
    let BuildNumberRegex = Regex("BuildNumber=(\\d+)")
    
    func handle(logLine: LogLine) {
        let game = AppDelegate.instance().coreManager.game
        if !game.parsedBuildNumber {
            if let match = BuildNumberRegex.matches(logLine.line).first, let build = Int(match.value) {
                game.set(buildNumber: build)
                game.parsedBuildNumber = true
                return
            }
        }

        let matches = PlayerRegex.matches(logLine.line)
        if matches.count == 2 {
            let playerId = Int(matches[0].value)
            let playerName = matches[1].value
            if playerName != "UNKNOWN HUMAN PLAYER" {
                game.playerIdsByPlayerName[playerName] = playerId
            }
        }
    }
}
