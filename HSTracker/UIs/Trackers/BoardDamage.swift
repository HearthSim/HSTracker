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
            .foregroundColor(NSColor.whiteColor())
            .strokeWidth(-1.5)
            .strokeColor(NSColor.blackColor())
            .alignment(.Center)
        
        self.window!.styleMask = NSBorderlessWindowMask
        self.window!.ignoresMouseEvents = true
        self.window!.level = Int(CGWindowLevelForKey(CGWindowLevelKey.ScreenSaverWindowLevelKey))
        
        self.window!.opaque = false
        self.window!.hasShadow = false
        self.window!.backgroundColor = NSColor.clearColor()
        
        NSNotificationCenter.defaultCenter()
            .addObserver(self,
                         selector: #selector(BoardDamage.hearthstoneActive(_:)),
                         name: "hearthstone_active",
                         object: nil)
    }
    
    func hearthstoneActive(notification: NSNotification) {
        let hs = Hearthstone.instance
        
        let level: Int
        if hs.hearthstoneActive {
            level = Int(CGWindowLevelForKey(CGWindowLevelKey.ScreenSaverWindowLevelKey))
        } else {
            level = Int(CGWindowLevelForKey(CGWindowLevelKey.NormalWindowLevelKey))
        }
        self.window!.level = level
    }
    
    func update(attack: Int) {      
        damage.attributedStringValue = NSAttributedString(string: "\(attack)",
                                                          attributes: attributes)
    }
}