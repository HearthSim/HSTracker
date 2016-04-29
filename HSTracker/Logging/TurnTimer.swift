//
//  TurnTimer.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 12/03/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import CleanroomLogger

@objc final class TurnTimer: NSObject {
    static let instance = TurnTimer()

    private(set) var seconds: Int = 75
    private(set) var playerSeconds: Int = 0
    private(set) var opponentSeconds: Int = 0
    private var turnTime: Int = 75
    private var timer: NSTimer?
    private var isPlayersTurn: Bool {
        return game?.playerEntity?.hasTag(.CURRENT_PLAYER) ?? false
    }
    private var game: Game?

    func setPlayer(player: PlayerType) {
        guard let _ = game else {
            seconds = 75
            return
        }

        if player == .Player && game!.playerEntity != nil {
            seconds = game!.playerEntity!.hasTag(.TIMEOUT)
                ? game!.playerEntity!.getTag(.TIMEOUT) : 75
        } else if player == .Opponent && game!.opponentEntity != nil {
            seconds = game!.opponentEntity!.hasTag(.TIMEOUT)
                ? game!.opponentEntity!.getTag(.TIMEOUT) : 75
        } else {
            seconds = 75
            Log.warning?.message("Could not update timer, both player entities are null")
        }
    }

    func start(game: Game?) {
        guard let _ = game else {
            Log.warning?.message("Could not start timer, game is null")
            return
        }
        Log.info?.message("Starting turn timer")
        if self.game != nil {
            Log.warning?.message("Turn timer is already running")
            return
        }
        self.game = game
        playerSeconds = 0
        opponentSeconds = 0
        seconds = 75

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            if game!.playerEntity == nil {
                Log.verbose?.message("Waiting for player entity")
                while game!.playerEntity == nil {
                    NSThread.sleepForTimeInterval(0.1)
                }
            }
            if game!.opponentEntity == nil {
                Log.verbose?.message("Waiting for player entity")
                while game!.opponentEntity == nil {
                    NSThread.sleepForTimeInterval(0.1)
                }
            }

            dispatch_async(dispatch_get_main_queue()) {
                self.timer = NSTimer.scheduledTimerWithTimeInterval(1,
                    target: self,
                    selector: #selector(TurnTimer.timerTick),
                    userInfo: nil,
                    repeats: true)
            }
        }
    }

    func stop() {
        guard let _ = game else {return}

        Log.info?.message("Stopping turn timer")
        timer?.invalidate()
        game = nil
    }

    func timerTick() {
        if seconds > 0 {
            seconds -= 1
        }

        if Game.instance.isMulliganDone() {
            if isPlayersTurn {
                playerSeconds += 1
            } else {
                opponentSeconds += 1
            }
        }
        dispatch_async(dispatch_get_main_queue()) {
            Game.instance.timerHud?.tick(self.seconds, self.playerSeconds, self.opponentSeconds)
        }
    }
}
