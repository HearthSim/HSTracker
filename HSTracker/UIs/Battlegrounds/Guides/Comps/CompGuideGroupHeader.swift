//
//  CompGuideGroupHeader.swift
//  HSTracker
//
//  Created by Francisco Moraes on 1/12/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class CompGuideGroupHeader: NSView {
    @IBOutlet weak var background: NSView!
    @IBOutlet weak var tier: NSTextField!
    
    func update(_ gradient: CALayer, _ tier: String) {
        background.wantsLayer = true
        background.layer = gradient
        
        self.tier.stringValue = tier
    }
}
