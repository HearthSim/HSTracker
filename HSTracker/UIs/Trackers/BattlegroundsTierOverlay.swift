//
//  BattlegroundsTierOverlay.swift
//  HSTracker
//
//  Created by Martin BONNIN on 04/01/2020.
//  Copyright © 2020 Benjamin Michotte. All rights reserved.
//

import Foundation

class BattlegroundsTierOverlay: OverWindowController {
    
    @IBOutlet weak var tierOverlay: BattlegroundsTierOverlayView!
    
    override var alwaysLocked: Bool {
        return true
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()
    }
    
    override func updateFrames() {
    }
}
