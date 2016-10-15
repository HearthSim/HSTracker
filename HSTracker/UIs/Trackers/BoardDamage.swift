//
//  BoardDamage.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 9/06/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import TextAttributes

class BoardDamage: NSWindowController {
    
    @IBOutlet weak var damage: NSTextField!
    let attributes = TextAttributes()
    
    override func windowDidLoad() {
        super.windowDidLoad()
        
        attributes
            .font(NSFont(name: "Belwe Bd BT", size: 18))
            .foregroundColor(.white)
            .strokeWidth(-1.5)
            .strokeColor(.black)
            .alignment(.center)
        
        self.window!.styleMask = [NSBorderlessWindowMask, NSNonactivatingPanelMask]
        self.window!.ignoresMouseEvents = true
        self.window!.level = Int(CGWindowLevelForKey(CGWindowLevelKey.screenSaverWindow))
        
        self.window!.isOpaque = false
        self.window!.hasShadow = false
        self.window!.backgroundColor = NSColor.clear
        
        NotificationCenter.default
            .addObserver(self,
                         selector: #selector(BoardDamage.hearthstoneActive(_:)),
                         name: NSNotification.Name(rawValue: "hearthstone_active"),
                         object: nil)
        
        self.window!.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        if let panel = self.window as? NSPanel {
            panel.isFloatingPanel = true
        }
        
        NSWorkspace.shared().notificationCenter
            .addObserver(self, selector: #selector(BoardDamage.bringToFront),
                         name: NSNotification.Name.NSWorkspaceActiveSpaceDidChange, object: nil)
        
        self.window?.orderFront(nil) // must be called after style change
    }

    func bringToFront() {
        self.window?.orderFront(nil)
    }
    
    func hearthstoneActive(_ notification: Notification) {
        let hs = Hearthstone.instance
        
        let level: Int
        if hs.hearthstoneActive {
            level = Int(CGWindowLevelForKey(CGWindowLevelKey.screenSaverWindow))
        } else {
            level = Int(CGWindowLevelForKey(CGWindowLevelKey.normalWindow))
        }
        self.window!.level = level
    }
    
    func update(attack: Int) {      
        damage.attributedStringValue = NSAttributedString(string: "\(attack)",
                                                          attributes: attributes)
    }
}
