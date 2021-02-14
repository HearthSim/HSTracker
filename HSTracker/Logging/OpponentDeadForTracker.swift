//
//  OpponentDeadForTracker.swift
//  HSTracker
//
//  Created by Francisco Moraes on 2/7/21.
//  Copyright © 2021 Benjamin Michotte. All rights reserved.
//

import Foundation

class OpponentDeadForTracker {
    private static var _uniqueDeadHeroes = [String]()
    private static var _deadTracker = [Int]()
    
    static let KelThuzadCardId = "KelThuzad"
    static let NextOpponentCheckDelay = 0.500
    
    static func resetOpponentDeadForTracker() {
        logger.debug("Resetting dead heroes")
        _uniqueDeadHeroes.removeAll()
        _deadTracker.removeAll()
        AppDelegate.instance().coreManager.game.windowManager.battlegroundsOverlay.view.resetNextOpponentLeaderboardPosition()
    }
    
    static func shoppingStarted(game: Game) {
        if game.turnNumber() <= 1 {
            resetOpponentDeadForTracker()
        }
        for i in 0..<_deadTracker.count {
            _deadTracker[i] += 1
        }
        let deadHeroes = game.entities.values.filter { x in x.isHero && x.health <= 0 }
        for hero in deadHeroes {
            let id: String = game.getCorrectBoardstateHeroId(heroId: hero.cardId)
            if !id.contains(KelThuzadCardId) && !_uniqueDeadHeroes.contains(id) {
                _deadTracker.append(0)
                _uniqueDeadHeroes.append(id)
            }
        }
        _deadTracker.sort(by: { x, y in return y < x })
        DispatchQueue.main.async {
            AppDelegate.instance().coreManager.game.windowManager.battlegroundsOverlay.view.updateOpponentDeadForTurns(turns: _deadTracker)
        }
        let currentPlayer = game.entities.values.first(where: { x in x.isCurrentPlayer })
        //We loop because the next opponent tag is set slightly after the start of shopping (when this function is called).
        var prev = -1
        for _ in 0 ..< 5 {
            if let currentPlayer = currentPlayer, currentPlayer.has(tag: GameTag.next_opponent_player_id) {
                let nextOpponent = game.entities.values.first(where: { x in x[GameTag.player_id] == currentPlayer[GameTag.next_opponent_player_id] })
                if let nextOpponent = nextOpponent {
                    let leaderboardPlace = nextOpponent[GameTag.player_leaderboard_place]
                    if leaderboardPlace > 0 && leaderboardPlace < 8 && leaderboardPlace != prev {
                        prev = leaderboardPlace
                        logger.debug("Updating dead tracker with \(leaderboardPlace), id=\(nextOpponent[.entity_id]), player_id=\(nextOpponent[.player_id])")
                        DispatchQueue.main.async {
                            AppDelegate.instance().coreManager.game.windowManager.battlegroundsOverlay.view.positionDeadForText(nextOpponentLeaderboardPosition: leaderboardPlace)
                        }
                    }
                }
            }
            Thread.sleep(forTimeInterval: NextOpponentCheckDelay)
        }
    }
}
