//
//  TurnCounter.swift
//  HSTracker
//
//  Created by Francisco Moraes on 10/6/20.
//  Copyright © 2020 Benjamin Michotte. All rights reserved.
//

import Foundation

class TurnCounter: OverWindowController {

    @objc dynamic var turnLabel = ""

    override func windowDidLoad() {
        super.windowDidLoad()
        
        turnLabel = ""
    }
 
    func setTurnNumber(turn: Int) {
        guard Settings.showTurnCounter else {
            turnLabel = ""
            return
        }

        turnLabel = String(format: String.localizedString("Turn %d", comment: ""), max(turn, 1))
    }
}
