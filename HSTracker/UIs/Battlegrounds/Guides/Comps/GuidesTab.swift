//
//  GuidesTab.swift
//  HSTracker
//
//  Created by Francisco Moraes on 1/14/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class GuidesTab: OverWindowController {
    @IBOutlet var tab1: NSBox!
    @IBOutlet var tab2: NSBox!
    
    @IBOutlet var compsGuides: CompsGuides!
    
    override var alwaysLocked: Bool {
        return true
    }
    
    override func updateFrames() {
    }
    
    override func awakeFromNib() {
        tab1.wantsLayer = true
        tab2.wantsLayer = true
        tab1.borders(for: [.minX, .maxY, .maxX], color: NSColor.fromHexString(hex: "#3f4346") ?? NSColor.black)
        tab2.borders(for: [.minY], color: NSColor.fromHexString(hex: "#3f4346") ?? NSColor.black)
    }
}
