//
//  ExperienceOverlay.swift
//  HSTracker
//
//  Created by Francisco Moraes on 1/9/21.
//  Copyright © 2021 Benjamin Michotte. All rights reserved.
//

import Foundation

class ExperienceOverlay: OverWindowController {
    override var alwaysLocked: Bool { true }
    var experienceTracker = ExperienceTracker()
    var visible = false
    
    override func windowDidLoad() {
        super.windowDidLoad()
        self.window!.contentView = experienceTracker
    }
}
