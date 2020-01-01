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

class BattlegroundsOverlay: OverWindowController {
    
    override func windowDidLoad() {
        super.windowDidLoad()
        self.window!.contentView = BattlegroundsOverlayView()
        //self.window!.backgroundColor = NSColor.brown
    }
    
    func setHeroes(heroes: [DeckEntry.Hero]) {
        (self.window?.contentView as? BattlegroundsOverlayView)?.setHeroes(heroes: heroes)
    }
}
