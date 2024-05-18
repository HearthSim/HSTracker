//
//  BattlegroundsBoardState.swift
//  HSTracker
//
//  Created by Francisco Moraes on 5/18/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class BattlegroundsBoardState {
    
    fileprivate var lastKnownBattlegroundsBoardState = SynchronizedDictionary<Int, BoardSnapshot>()
    private let game: Game
    
    init(game: Game) {
        self.game = game
    }
    
    func snapshotCurrentBoard() {
        guard let opponentHero = game.entities.values.first(where: { x in x.isHero && x.isInZone(zone: Zone.play) && x.isControlled(by: game.opponent.id) }) else {
            return
        }
        if opponentHero.cardId.isEmpty {
            return
        }
        let playerId = opponentHero[.player_id]
        if playerId == 0 {
            return
        }
        let entities = game.entities.values.filter { x in x.isMinion && x.isInZone(zone: .play) && x.isControlled(by: game.opponent.id) }.compactMap { x in x.copy() }
        logger.info("Snapshotting board state for \(opponentHero.card.name) with player id \(playerId) (\(entities.count) entities)")
        let current = lastKnownBattlegroundsBoardState[playerId]
        let board = BoardSnapshot(entities: entities, turn: game.turnNumber(), previous: current)
        
        lastKnownBattlegroundsBoardState[playerId] = board
    }
    
    func getSnapshot(entityId: Int) -> BoardSnapshot? {
        guard let entity = game.entities[entityId] else {
            return nil
        }
        
        return lastKnownBattlegroundsBoardState[entity[.player_id]]
    }
    
    func reset() {
        lastKnownBattlegroundsBoardState.removeAll()
    }
    
    func handlePlayerTechLevel(_ id: Int, _ techLevel: Int) {
        var snapshot = lastKnownBattlegroundsBoardState[id]
        
        if snapshot == nil {
            snapshot = BoardSnapshot(entities: [], turn: -1)
            lastKnownBattlegroundsBoardState[id] = snapshot
        }
        
        if let snapshot = snapshot {
            snapshot.techLevel[techLevel - 1] = game.turnNumber()
        }
    }
    
    func handlePlayerTriples(_ id: Int, _ techLevel: Int, _ triples: Int) {
        var snapshot = lastKnownBattlegroundsBoardState[id]
        
        if snapshot == nil {
            snapshot = BoardSnapshot(entities: [], turn: -1)
            lastKnownBattlegroundsBoardState[id] = snapshot
        }
        
        if let snapshot = snapshot {
            snapshot.triples[techLevel - 1] += triples
        }
    }
    
    func handlePlayerBuddiesGained(_ id: Int, _ num: Int) {
        var snapshot = lastKnownBattlegroundsBoardState[id]
        
        if snapshot == nil {
            snapshot = BoardSnapshot(entities: [], turn: -1)
            lastKnownBattlegroundsBoardState[id] = snapshot
        }
        
        if let snapshot = snapshot {
            if num == 1 {
                snapshot.buddiesGained = 1
            } else if num == 2 {
                snapshot.buddiesGained = 3
            }
        }
    }
    
    func handlePlayerHeroPowerQuestRewardDatabaseId(_ id: Int, _ num: Int) {
        var snapshot = lastKnownBattlegroundsBoardState[id]
        
        if snapshot == nil {
            snapshot = BoardSnapshot(entities: [], turn: -1)
            lastKnownBattlegroundsBoardState[id] = snapshot
        }
        
        if let snapshot = snapshot {
            snapshot.questHP = num
        }
    }
    
    func handlePlayerHeroPowerQuestRewardCompleted(_ id: Int) {
        var snapshot = lastKnownBattlegroundsBoardState[id]
        
        if snapshot == nil {
            snapshot = BoardSnapshot(entities: [], turn: -1)
            lastKnownBattlegroundsBoardState[id] = snapshot
        }
        
        if let snapshot = snapshot {
            snapshot.questHPTurn = game.turnNumber()
        }
    }
    
    func handlePlayerHeroQuestRewardDatabaseId(_ id: Int, _ num: Int) {
        var snapshot = lastKnownBattlegroundsBoardState[id]
        
        if snapshot == nil {
            snapshot = BoardSnapshot(entities: [], turn: -1)
            lastKnownBattlegroundsBoardState[id] = snapshot
        }
        
        if let snapshot = snapshot {
            snapshot.quest = num
        }
    }
    
    func handlePlayerHeroQuestRewardCompleted(_ id: Int) {
        var snapshot = lastKnownBattlegroundsBoardState[id]
        
        if snapshot == nil {
            snapshot = BoardSnapshot(entities: [], turn: -1)
            lastKnownBattlegroundsBoardState[id] = snapshot
        }
        
        if let snapshot = snapshot {
            snapshot.questHPTurn = game.turnNumber()
        }
    }
}
