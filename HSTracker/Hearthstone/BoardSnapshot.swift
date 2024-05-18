//
//  BoardSnapshot.swift
//  HSTracker
//
//  Created by Francisco Moraes on 5/18/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class BoardSnapshot {
    let entities: [Entity]
    let turn: Int
    var buddiesGained: Int
    var techLevel: [Int]
    var triples: [Int]
    var questHP: Int
    var questHPTurn: Int
    var quest: Int
    var questTurn: Int
    
    init(entities: [Entity], turn: Int, previous: BoardSnapshot? = nil) {
        self.entities = entities
        self.turn = turn
        self.buddiesGained = previous?.buddiesGained ?? 0
        self.techLevel = previous?.techLevel ?? [ 0, 0, 0, 0, 0, 0 ]
        self.triples = previous?.triples ?? [ 0, 0, 0, 0, 0, 0 ]
        self.questHP = previous?.questHP ?? 0
        self.questHPTurn = previous?.questHPTurn ?? 0
        self.quest = previous?.quest ?? 0
        self.questTurn = previous?.questTurn ?? 0
    }
}
