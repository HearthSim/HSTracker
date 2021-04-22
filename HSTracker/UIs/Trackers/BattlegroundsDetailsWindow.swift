//
//  CollectionFeedback.swift
//  HSTracker
//
//  Created by Martin BONNIN on 13/11/2019.
//  Copyright © 2019 HearthSim LLC. All rights reserved.
//

import Foundation
import TextAttributes

class BattlegroundsDetailsWindow: OverWindowController {
    let battlegroundsDetailsView = BattlegroundsDetailsView()
    
    override func windowDidLoad() {
        
        self.window!.contentView = battlegroundsDetailsView

        super.windowDidLoad()
    }
    
    func setBoard(board: BoardSnapshot) {
        self.battlegroundsDetailsView.setBoard(board: board)
    }
    
    func setCombatHistory(id: Int, cardId: String, history: [MirrorCombatHistory]) {
        self.battlegroundsDetailsView.setCombatHistory(id: id, cardId: cardId, history: history)
    }
    
    func reset() {
        self.battlegroundsDetailsView.reset()
    }
}
