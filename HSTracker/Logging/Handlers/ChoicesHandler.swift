//
//  ChoicesHandler.swift
//  HSTracker
//
//  Created by Francisco Moraes on 12/8/23.
//  Copyright © 2023 Benjamin Michotte. All rights reserved.
//

import Foundation

class ChoicesHandler: LogEventParser {
    let game: Game
    let sendChoicesHandler = SendChoicesHandler()
    
    static let sendChoicesHeaderRegex = Regex(#"id=(\d+) ChoiceType=(\w+)"#)
    static let sendChoicesBodyRegex = Regex(#"m_chosenEntities\[(\d+)]=.* id=(\d+)"#)
    
    init(with game: Game) {
        self.game = game
    }
    
    func handle(logLine: LogLine) {
        var matches = ChoicesHandler.sendChoicesHeaderRegex.matches(logLine.content)
        if matches.count > 0 {
            if let choiceId = Int(matches[0].value), let choiceType = ChoiceType(rawString: matches[1].value) {
                sendChoicesHandler.sendChoices(id: choiceId, choiceType: choiceType, game: game)
            }
        } else {
            matches = ChoicesHandler.sendChoicesBodyRegex.matches(logLine.content)
            if matches.count > 0 {
                if let index = Int(matches[0].value), let entityId = Int(matches[1].value) {
                    sendChoicesHandler.sendChoice(index: index, entityId: entityId, game: game)
                }
            } else {
                // Terminate the current Choice.
                sendChoicesHandler.flush(game: game)
            }
        }
    }
}
