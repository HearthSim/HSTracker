//
//  TurnTimer.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 12/03/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation

@objc final class TurnTimer: NSObject {
	
	/** How long a turn can last in seconds */
	private static let TurnLengthSec = 75

    private(set) var seconds: Int = 75
    private(set) var playerSeconds: Int = 0
    private(set) var opponentSeconds: Int = 0
    private var turnTime: Int = 75
    private var timer: Timer?
	weak var timerHud: TimerHud?
	
	private var currentPlayer: PlayerType = .player
	
	init(gui: TimerHud) {
		self.timerHud = gui
	}
	
    func startTurn(for player: PlayerType, timeout: Int = -1) {
		seconds = TurnTimer.TurnLengthSec
		self.currentPlayer = player
		
		timer?.invalidate()
		self.timer = Timer(timeInterval: 1,
		                   target: self,
		                   selector: #selector(self.timerTick),
		                   userInfo: nil, repeats: true)
		RunLoop.main.add(timer!, forMode: RunLoop.Mode.default)
		
        if timeout < 0 {
            seconds = 75
        } else {
            seconds = timeout
        }

    }

    func start() {

        playerSeconds = 0
        opponentSeconds = 0
        seconds = 75
		
		timer?.invalidate()
    }

    func stop() {
        timer?.invalidate()
    }

    @objc func timerTick() {

        if seconds > 0 {
            seconds -= 1
        }
		
		if self.currentPlayer == .player {
			self.playerSeconds += 1
		} else {
			self.opponentSeconds += 1
		}

        /*if game.isMulliganDone() {
            if isPlayersTurn {
                playerSeconds += 1
            } else {
                opponentSeconds += 1
            }
        }*/
		DispatchQueue.main.async { [unowned(unsafe) self] in
			self.timerHud?.tick(seconds: self.seconds,
                    playerSeconds: self.playerSeconds,
                    opponentSeconds: self.opponentSeconds)
		}
		
    }
}
