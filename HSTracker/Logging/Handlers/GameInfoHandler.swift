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
    
    func handle(logLine: LogLine) {
        let matches = PlayerRegex.matches(logLine.line)
        if matches.count == 2 {
            let playerId = Int(matches[0].value)
            let playerName = matches[1].value
            if playerName != "UNKNOWN HUMAN PLAYER" {
                let game = AppDelegate.instance().coreManager.game
                game.playerIdsByPlayerName[playerName] = playerId
            }
        }
    }
}
