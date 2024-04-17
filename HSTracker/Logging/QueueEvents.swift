//
//  QueueEvents.swift
//  HSTracker
//
//  Created by Francisco Moraes on 12/2/22.
//  Copyright © 2022 Benjamin Michotte. All rights reserved.
//

import Foundation

class QueueEvents {
    static let lettuceModes: [Mode] = [ .lettuce_bounty_board, .lettuce_map, .lettuce_play, .lettuce_coop, .lettuce_friendly, .lettuce_bounty_team_select ]
    static let modes: [Mode] = [ .tavern_brawl, .tournament, .draft, .friendly, .adventure, .bacon ]
    
    private let _game: Game
    
    var isInQueue = false
    
    init(game: Game) {
        _game = game
    }
    
    func handle(_ e: QueueEventArgs) {
        isInQueue = e.isInQueue
        
        if !_game.isInMenu {
            return
        }
        if !QueueEvents.modes.contains(_game.currentMode ?? Mode.invalid) && !QueueEvents.lettuceModes.contains(_game.currentMode ?? Mode.invalid) {
            return
        }
        if _game.currentMode == .tournament {
            _game.setConstructedQueue(e.isInQueue)
        }
        if _game.currentMode == .bacon {
            _game.setBaconQueue(e.isInQueue)
        }
        if e.isInQueue {
            // _game.metadata.enqueueTime = Date.now()
            
            logger.info("Now in queue")
            if let deck = AppDelegate.instance().coreManager.autoDetectDeck(mode: _game.currentMode ?? .invalid) {
                _game.set(activeDeck: deck, autoDetected: true)
            } else if Settings.autoDeckDetection {
                _game.set(activeDeckId: nil, autoDetected: true)
            }
        } else {
            logger.info("No longer in queue")
        }
    }

}
