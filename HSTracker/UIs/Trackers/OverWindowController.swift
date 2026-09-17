//
//  OverWindowController.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 19/10/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import Cocoa

class OverWindowController: NSWindowController {
    var alwaysLocked: Bool { false }
    
    override func windowDidLoad() {
        super.windowDidLoad()

        self.window!.backgroundColor = NSColor.clear
        self.window!.isOpaque = false
        self.window!.hasShadow = false
        self.window!.acceptsMouseMovedEvents = true

        if let panel = self.window as? NSPanel {
            panel.isFloatingPanel = true
        }
    }

    /**
        Updates the UI based on stored data. This method should only be called from the main thread
     */
    func updateFrames() {
        // If the windows are unlocked, we want to be able to click on them to move them
        self.window!.ignoresMouseEvents = Settings.windowsLocked
    }
}
