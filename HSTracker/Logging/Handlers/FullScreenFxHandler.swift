//
//  FullScreenFxHandler.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 11/08/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import CleanroomLogger

struct FullScreenFxHandler {
    
    let HeroRegex = "BeginEffect blur \\d => 1"
    
    private var lastQueueTime: NSDate = NSDate.distantPast()
    
    mutating func handle(game: Game, logLine: LogLine) {
        if logLine.line.match(HeroRegex) && game.isInMenu
            && (game.currentMode == .tavern_brawl || game.currentMode == .tournament
                || game.currentMode == .draft ) {
            game.enqueueTime = logLine.time
            Log.info?.message("now in queue (\(logLine.time))")
            if NSDate().diffInSeconds(logLine.time) > 5
                || !game.isInMenu || logLine.time <= lastQueueTime {
                return
            }
            lastQueueTime = logLine.time
        }
    }
}
