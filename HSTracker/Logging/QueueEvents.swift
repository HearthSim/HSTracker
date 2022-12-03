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
    
    init(game: Game) {
        _game = game
    }
    
    func handle(_ e: QueueEventArgs) {
        if !_game.isInMenu {
            return
        }
        if !QueueEvents.modes.contains(_game.currentMode ?? Mode.invalid) && !QueueEvents.lettuceModes.contains(_game.currentMode ?? Mode.invalid) {
            return
        }
        if e.isInQueue {
            // _game.metadata.enqueueTime = Date.now()
            
            logger.info("Now in queue")
            if let deck = AppDelegate.instance().coreManager.autoDetectDeck(mode: _game.currentMode ?? .invalid) {
                _game.set(activeDeckId: deck.deckId, autoDetected: true)
            }
        }
    }

}
