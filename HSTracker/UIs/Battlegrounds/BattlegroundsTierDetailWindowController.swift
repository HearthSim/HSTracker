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
    
    override func windowDidLoad() {
        super.windowDidLoad()
    }
    
    func setTier(tier: Int) {
        detailsView?.setTier(tier: tier)
    }
}
