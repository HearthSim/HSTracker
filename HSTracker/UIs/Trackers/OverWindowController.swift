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

    func setWindowSizes() {
        var width: Double
        switch Settings.cardSize {
        case .tiny: width = kTinyFrameWidth
        case .small: width = kSmallFrameWidth
        case .medium: width = kMediumFrameWidth
        case .huge: width = kHighRowFrameWidth
        case .big: width = kFrameWidth
        }

        guard let window = self.window else { return }

        window.contentMinSize = NSSize(width: CGFloat(width), height: 400)
        window.contentMaxSize = NSSize(width: CGFloat(width),
                                             height: NSScreen.main!.frame.height)
    }
    
    /**
        Updates the UI based on stored data. This method should only be called from the main thread
     */
    func updateFrames() {
        // update gui elements based on internal data
    }
}
