//
//  FullScreenFxHandler.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 11/08/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import CleanroomLogger

class FullScreenFxHandler: LogEventHandler {

    let BeginBlurRegex = "BeginEffect blur \\d => 1"
    
    private var lastQueueTime: Date = Date.distantPast
	
	private unowned let hearthstone: Hearthstone
	
	init(with hearthstone: Hearthstone) {
		self.hearthstone = hearthstone
	}
    
    func handle(logLine: LogLine) {
        guard let currentMode = hearthstone.game.currentMode else {
            return
        }

        let modes: [Mode] = [.tavern_brawl, .tournament, .draft, .friendly, .adventure]
        if logLine.line.match(BeginBlurRegex) && hearthstone.game.isInMenu && modes.contains(currentMode) {
            hearthstone.game.enqueueTime = logLine.time
            Log.info?.message("now in queue (\(logLine.time))")
            if abs(logLine.time.timeIntervalSinceNow) > 5
                || !hearthstone.game.isInMenu || logLine.time <= lastQueueTime {
                return
            }
            lastQueueTime = logLine.time

            if Settings.autoDeckDetection {
				if let deck = hearthstone.autoDetectDeck(mode: currentMode) {
					hearthstone.game.set(activeDeckId: deck.deckId)
				} else {
					hearthstone.game.set(activeDeckId: nil)
				}
            }
        }
    }
}
