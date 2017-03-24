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
    private var timer: Timer?
    private var isPlayersTurn: Bool {
        return game?.playerEntity?.has(tag: .current_player) ?? false
    }
    private var game: Game?

    func set(player: PlayerType) {
        guard let game = game else {
            seconds = 75
            return
        }

        if player == .player && game.playerEntity != nil {
            seconds = game.playerEntity!.has(tag: .timeout)
                    ? game.playerEntity![.timeout] : 75
        } else if player == .opponent && game.opponentEntity != nil {
            seconds = game.opponentEntity!.has(tag: .timeout)
                    ? game.opponentEntity![.timeout] : 75
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

        DispatchQueue.global().async {
                    guard let game = game else {
                        return
                    }
                    if game.playerEntity == nil {
                        Log.verbose?.message("Waiting for player entity")
                        while game.playerEntity == nil {
                            Thread.sleep(forTimeInterval: 0.1)
                        }
                    }
                    if game.opponentEntity == nil {
                        Log.verbose?.message("Waiting for player entity")
                        while game.opponentEntity == nil {
                            Thread.sleep(forTimeInterval: 0.1)
                        }
                    }

                    DispatchQueue.main.async {
                        if self.timer != nil {
                            self.timer!.invalidate()
                        }
                        self.timer = Timer.scheduledTimer(timeInterval: 1,
                                target: self,
                                selector: #selector(self.timerTick),
                                userInfo: nil,
                                repeats: true)
                    }
                }
    }

    func stop() {
        guard let _ = game else {
            return
        }

        Log.info?.message("Stopping turn timer")
        timer?.invalidate()
        game = nil
    }

    func timerTick() {
        guard let game = game else {
            return
        }

        if seconds > 0 {
            seconds -= 1
        }

        if game.isMulliganDone() {
            if isPlayersTurn {
                playerSeconds += 1
            } else {
                opponentSeconds += 1
            }
        }/* TODO: rework turn timer
        DispatchQueue.main.async { [weak self] in
            guard let game = self?.game,
                  let windowManager = game.windowManager,
                  let seconds = self?.seconds,
                  let playerSeconds = self?.playerSeconds,
                  let opponentSeconds = self?.opponentSeconds else {
                return
            }
            windowManager.timerHud.tick(seconds: seconds,
                    playerSeconds: playerSeconds,
                    opponentSeconds: opponentSeconds)
        }*/
    }
}
