//
//  BattlegroundsTrinketPickState.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/25/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class BattlegroundsTrinketPickState {
    private(set) var choiceId: Int
    private(set) var params: BattlegroundsTrinketPickParams?
    private(set) var chosenTrinketDbfId: Int?
    
    init(choiceId: Int, params: BattlegroundsTrinketPickParams? = nil) {
        self.choiceId = choiceId
        self.params = params
    }
    
    func pickTrinket(trinket: Entity) {
        chosenTrinketDbfId = trinket.card.dbfId
    }
}
