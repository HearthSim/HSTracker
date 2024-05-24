//
//  OpponentDeadForTracker.swift
//  HSTracker
//
//  Created by Francisco Moraes on 2/7/21.
//  Copyright © 2021 Benjamin Michotte. All rights reserved.
//

import Foundation

class OpponentDeadForTracker {
    private static var _uniqueDeadPlayers = [Int]()
    private static var _deadTracker = [Int]()
    
    static func shoppingStarted(game: Game) {
        if game.turnNumber() <= 1 {
            reset()
        }
        for i in 0..<_deadTracker.count {
            _deadTracker[i] += 1
        }
        let deadHeroes = game.entities.values.filter { x in x.isHero && x.health <= 0 }
        logger.debug("Dead heroes: \(deadHeroes.compactMap({ x in x.cardId}))")
        for hero in deadHeroes {
            let playerId = hero[.player_id]
            if playerId > 0 && !_uniqueDeadPlayers.contains(playerId) {
                _deadTracker.append(0)
                _uniqueDeadPlayers.append(playerId)
            }
        }
        _deadTracker.sort(by: { x, y in return y < x })
        DispatchQueue.main.async {
            AppDelegate.instance().coreManager.game.windowManager.battlegroundsOverlay.view.updateOpponentDeadForTurns(turns: _deadTracker)
        }
    }
    
    static func setNextOpponentPlayerId(_ playerId: Int) {
        let game = AppDelegate.instance().coreManager.game
        guard let nextOpponent = game.entities.values.first(where: { x in x[GameTag.player_id] == playerId }) else {
            return
        }
        let leaderboardPlace = nextOpponent[GameTag.player_leaderboard_place]
        if leaderboardPlace > 0 && leaderboardPlace <= 8 {
            logger.debug("Updating dead tracker with \(leaderboardPlace), id=\(nextOpponent[.entity_id]), player_id=\(playerId)")
            DispatchQueue.main.async {
                AppDelegate.instance().coreManager.game.windowManager.battlegroundsOverlay.view.positionDeadForText(nextOpponentLeaderboardPosition: leaderboardPlace)
            }
        }
    }
    
    static func reset() {
        _uniqueDeadPlayers.removeAll()
        _deadTracker.removeAll()
        DispatchQueue.main.async {
            AppDelegate.instance().coreManager.game.windowManager.battlegroundsOverlay.view.updateOpponentDeadForTurns(turns: _deadTracker)
        }
    }
}
