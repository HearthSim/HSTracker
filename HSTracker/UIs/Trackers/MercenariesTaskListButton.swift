//
//  ExperienceOverlay.swift
//  HSTracker
//
//  Created by Francisco Moraes on 1/9/21.
//  Copyright © 2021 Benjamin Michotte. All rights reserved.
//

import Foundation
import AppKit

class MercenariesTaskListButton: OverWindowController {
    override var alwaysLocked: Bool { true }
    var visible = false
    private var showMercTasks = false
    
    override func windowDidLoad() {
        super.windowDidLoad()
        let area = NSTrackingArea(rect: window!.contentView!.frame, options: [.inVisibleRect, .activeAlways, .mouseEnteredAndExited, .mouseMoved], owner: self, userInfo: nil)
        window!.contentView!.addTrackingArea(area)
    }
    
    override func mouseEntered(with event: NSEvent) {
        let wm = AppDelegate.instance().coreManager.game.windowManager
        showMercTasks = true
        DispatchQueue.main.asyncAfter(deadline: Dispatch.DispatchTime.now() + .milliseconds(150)) {
            if !self.showMercTasks {
                return
            }
            let taskList = wm.mercenariesTaskListView
            
            taskList.update()
            taskList.updateContent()
            
            let frame = SizeHelper.mercenariesTaskListView()
         
            wm.show(controller: taskList, show: true, frame: frame, title: nil, overlay: true)
        }
    }
    
    override func mouseExited(with event: NSEvent) {
        let windowManager = AppDelegate.instance().coreManager.game.windowManager
        
        showMercTasks = false
        windowManager.show(controller: windowManager.mercenariesTaskListView, show: false)
    }
}
