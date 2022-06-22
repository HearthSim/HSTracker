//
//  FullScreenFxHandler.swift
//  HSTracker
//
//  Created by Francisco Moraes on 4/2/21.
//  Copyright © 2021 Benjamin Michotte. All rights reserved.
//

import Foundation

class FullScreenFxHandler: LogEventParser {
    let beginBlurRegex = Regex("BeginEffect blur \\d => 1")

    private unowned(unsafe) let core: CoreManager

    private var _lastQueueTime: LogDate?
    
    init(coreManager: CoreManager) {
        core = coreManager
    }
    
    func handle(logLine: LogLine) {
        if beginBlurRegex.match(logLine.line) {
            let game = AppDelegate.instance().coreManager.game
            
            if game.isInMenu {
                switch game.currentMode {
                case .tavern_brawl, .tournament, .draft, .friendly, .adventure, .bacon:
                    logger.info("Now in queue \(logLine.time)")
                    if logLine.time.timeIntervalSinceNow > 5 || !game.isInMenu || _lastQueueTime != nil && logLine.time <= _lastQueueTime! {
                        return
                    }
                    _lastQueueTime = logLine.time
                    
                    if let deck = AppDelegate.instance().coreManager.autoDetectDeck(mode: game.currentMode ?? .invalid) {
                        game.set(activeDeckId: deck.deckId, autoDetected: true)
                    }

                default:
                    return
                }
            }
        }
    }
}
