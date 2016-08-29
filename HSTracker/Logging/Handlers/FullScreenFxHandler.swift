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
    
    static let HeroRegex = "BeginEffect blur \\d => 1"
    
    private var lastQueueTime: Double = NSDate.distantPast().timeIntervalSince1970
    
    mutating func handle(game: Game, logLine: LogLine) {
        if logLine.line.match(self.dynamicType.HeroRegex) && game.isInMenu
            && (game.currentMode == .TAVERN_BRAWL || game.currentMode == .TOURNAMENT
                || game.currentMode == .DRAFT ) {
            game.enqueueTime = logLine.time
            Log.info?.message("now in queue (\(logLine.time))")
            if (NSDate().timeIntervalSince1970 - logLine.time) > 5
                || !game.isInMenu || logLine.time <= lastQueueTime {
                return
            }
            lastQueueTime = logLine.time
        }
    }
}