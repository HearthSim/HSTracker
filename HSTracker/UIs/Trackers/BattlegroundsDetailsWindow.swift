//
//  CollectionFeedback.swift
//  HSTracker
//
//  Created by Martin BONNIN on 13/11/2019.
//  Copyright © 2019 HearthSim LLC. All rights reserved.
//

import Foundation
import TextAttributes
import kotlin_hslog

class BattlegroundsDetailsWindow: OverWindowController {
    let battlegroundsDetailsView = BattlegroundsDetailsView()
    
    override func windowDidLoad() {
        super.windowDidLoad()
        self.window!.contentView = self.battlegroundsDetailsView
    }
    
    func setBoard(board: BattlegroundsBoard) {
        self.battlegroundsDetailsView.setBoard(board: board)
    }
}
