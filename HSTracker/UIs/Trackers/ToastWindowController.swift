//
//  ToastWindowController.swift
//  HSTracker
//
//  Created by Martin BONNIN on 03/05/2020.
//  Copyright © 2020 Benjamin Michotte. All rights reserved.
//

import Foundation

class ToastWindowController: OverWindowController {
    init() {
        let panel = NSWindow()
        panel.styleMask.insert(.borderless)
        panel.styleMask.insert(.resizable)
        panel.hasShadow = false

        super.init(window: panel)

        self.window!.backgroundColor = NSColor.init(red: 0x48/255.0, green: 0x7E/255.0, blue: 0xAA/255.0, alpha: 1)
    }
        
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func updateFrames() {
        self.window!.ignoresMouseEvents = false
    }
}
