//
//  TurnTimer.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 12/03/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation

@objc class TurnTimer : NSObject {
    static let instance = TurnTimer()

    private(set) var seconds: Int = 90
    private(set) var playerSeconds: Int = 0
    private(set) var opponentSeconds: Int = 0
    private var turnTime: Int = 90
    private var timer: NSTimer?
    var currentActivePlayer: PlayerType = .Player

    func reset() {
        timer?.invalidate()

        seconds = turnTime
        playerSeconds = 0
        opponentSeconds = 0
    }

    func restart() {
        seconds = turnTime

        if let timer = timer {
            timer.invalidate()
        }

        timer = NSTimer.scheduledTimerWithTimeInterval(1, target: self,
            selector: "timerTick", userInfo: nil, repeats: true)
    }

    func timerTick() {
        if seconds > 0 {
            seconds -= 1
        }

        if Game.instance.isMulliganDone() {
            if currentActivePlayer == .Player {
                playerSeconds += 1
            }
            else {
                opponentSeconds += 1
            }
        }
        dispatch_async(dispatch_get_main_queue()) {
            Game.instance.timerHud?.tick(self.seconds, self.playerSeconds, self.opponentSeconds)
        }
    }
}