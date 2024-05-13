//
//  BattlegroundsTierDetailWindowController.swift
//  HSTracker
//
//  Created by Martin BONNIN on 04/01/2020.
//  Copyright © 2020 Benjamin Michotte. All rights reserved.
//

import Foundation

class BattlegroundsTierDetailWindowController: OverWindowController {
    @IBOutlet weak var detailsView: BattlegroundsTierDetailsView?
    
    override var alwaysLocked: Bool {
        return true
    }
    
    override func updateFrames() {
    }
    
    func setTier(tier: Int, isThorimRelevant: Bool) {
        detailsView?.setTier(tier: tier, isThorimRelevant: isThorimRelevant)
    }
}
