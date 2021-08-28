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
        let panel = NSPanel()
        panel.styleMask.insert(.borderless)
        panel.styleMask.insert(.resizable)
        panel.styleMask.insert(.nonactivatingPanel)
        panel.styleMask.remove(.titled)
        panel.styleMask.remove(.closable)
        panel.styleMask.remove(.resizable)
        panel.hasShadow = false
        panel.isReleasedWhenClosed = true
        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = false
        panel.collectionBehavior = [NSWindow.CollectionBehavior.canJoinAllSpaces, NSWindow.CollectionBehavior.fullScreenAuxiliary]

        super.init(window: panel)

        self.window!.backgroundColor = NSColor.init(red: 0x48/255.0, green: 0x7E/255.0, blue: 0xAA/255.0, alpha: 1)
    }
    
    var displayed = false
        
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func updateFrames() {
        self.window!.ignoresMouseEvents = false
    }
}
