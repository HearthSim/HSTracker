//
//  FullScreenFxHandler.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 11/08/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import CleanroomLogger
import RegexUtil

class FullScreenFxHandler: LogEventParser {

    let BeginBlurRegex: RegexPattern = "BeginEffect blur \\d => 1"
    
	private var lastQueueTime: LogDate = LogDate(date: Date.distantPast)
	
	private unowned(unsafe) let coreManager: CoreManager
	
	init(with coreManager: CoreManager) {
		self.coreManager = coreManager
	}
    
    func handle(logLine: LogLine) {
        
        guard let currentMode = coreManager.game.currentMode else {
            return
        }

        let modes: [Mode] = [.tavern_brawl, .tournament, .draft, .friendly, .adventure]
        if logLine.line.match(BeginBlurRegex) && coreManager.game.isInMenu && modes.contains(currentMode) {
            // player entered queue
            coreManager.game.enqueueTime = logLine.time
            Log.info?.message("now in queue (\(logLine.time))")
            if abs(logLine.time.timeIntervalSinceNow) > 5
                || !coreManager.game.isInMenu || logLine.time <= lastQueueTime {
                return
            }
            lastQueueTime = logLine.time

            if Settings.autoDeckDetection {
				if let deck = CoreManager.autoDetectDeck(mode: currentMode) {
					coreManager.game.set(activeDeckId: deck.deckId, autoDetected: true)
				} else {
                    Log.warning?.message("could not autodetect deck (fullscreenFxHandler)")
					coreManager.game.set(activeDeckId: nil, autoDetected: false)
				}
            }
        }
    }
}
