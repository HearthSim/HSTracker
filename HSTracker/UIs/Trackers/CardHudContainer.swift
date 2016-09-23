//
//  CardHudContainer.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 16/06/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import CleanroomLogger

class CardHudContainer: NSWindowController {
    
    var positions: [Int: [NSPoint]] = [:]
    var huds: [CardHud] = []
    
    @IBOutlet weak var container: NSView!
    
    override func windowDidLoad() {
        super.windowDidLoad()
 
        self.window!.styleMask = NSBorderlessWindowMask | NSNonactivatingPanelMask
        //self.window!.ignoresMouseEvents = true
        self.window!.level = Int(CGWindowLevelForKey(CGWindowLevelKey.ScreenSaverWindowLevelKey))
        
        self.window!.opaque = false
        self.window!.hasShadow = false
        self.window!.backgroundColor = NSColor.clearColor()
        
        for _ in 0 ..< 10 {
            let hud = CardHud()
            hud.alphaValue = 0.0
            container.addSubview(hud)
            huds.append(hud)
        }
        initPoints()
        
        NSNotificationCenter.defaultCenter()
            .addObserver(self,
                         selector: #selector(BoardDamage.hearthstoneActive(_:)),
                         name: "hearthstone_active",
                         object: nil)
        self.window!.collectionBehavior = [.CanJoinAllSpaces, .FullScreenAuxiliary]
        
        if let panel = self.window as? NSPanel {
            panel.floatingPanel = true
        }
        
        NSWorkspace.sharedWorkspace().notificationCenter
            .addObserver(self, selector: #selector(CardHudContainer.bringToFront),
                         name: NSWorkspaceActiveSpaceDidChangeNotification, object: nil)
        
        self.window?.orderFront(nil) // must be called after style change
    }
    
    func bringToFront() {
        self.window?.orderFront(nil)
    }
    
    func initPoints() {
        positions[1] = [
            NSPoint(x: 144, y: -3)
        ]
        
        positions[2] = [
            NSPoint(x: 97, y: -1),
            NSPoint(x: 198, y: -1)
        ]
        
        positions[3] = [
            NSPoint(x: 42, y: 19),
            NSPoint(x: 146, y: -1),
            NSPoint(x: 245, y: 8)
        ]
        
        positions[4] = [
            NSPoint(x: 31, y: 28),
            NSPoint(x: 109, y: 6),
            NSPoint(x: 185, y: -1),
            NSPoint(x: 262, y: 5)
        ]
        
        positions[5] = [
            NSPoint(x: 21, y: 26),
            NSPoint(x: 87, y: 6),
            NSPoint(x: 148, y: -4),
            NSPoint(x: 211, y: -2),
            NSPoint(x: 274, y: 9)
        ]
        
        positions[6] = [
            NSPoint(x: 19, y: 36),
            NSPoint(x: 68, y: 15),
            NSPoint(x: 123, y: 2),
            NSPoint(x: 175, y: -3),
            NSPoint(x: 229, y: 0),
            NSPoint(x: 278, y: 9)
        ]
        
        positions[7] = [
            NSPoint(x: 12.0, y: 36.0),
            NSPoint(x: 57.0, y: 16.0),
            NSPoint(x: 104.0, y: 4.0),
            NSPoint(x: 153.0, y: -1.0),
            NSPoint(x: 194.0, y: -3.0),
            NSPoint(x: 240.0, y: 6.0),
            NSPoint(x: 283.0, y: 19.0)
        ]
        
        positions[8] = [
            NSPoint(x: 14.0, y: 38.0),
            NSPoint(x: 52.0, y: 22.0),
            NSPoint(x: 92.0, y: 6.0),
            NSPoint(x: 134.0, y: -2.0),
            NSPoint(x: 172.0, y: -5.0),
            NSPoint(x: 210.0, y: -4.0),
            NSPoint(x: 251.0, y: 1.0),
            NSPoint(x: 289.0, y: 10.0)
        ]
        
        positions[9] = [
            NSPoint(x: 16.0, y: 38.0),
            NSPoint(x: 57.0, y: 25.0),
            NSPoint(x: 94.0, y: 12.0),
            NSPoint(x: 127.0, y: 3.0),
            NSPoint(x: 162.0, y: -1.0),
            NSPoint(x: 201.0, y: -6.0),
            NSPoint(x: 238.0, y: 2.0),
            NSPoint(x: 276.0, y: 13.0),
            NSPoint(x: 315.0, y: 28.0)
        ]
        
        positions[10] = [
            NSPoint(x: 21.0, y: 40.0),
            NSPoint(x: 53.0, y: 30.0),
            NSPoint(x: 86.0, y: 20.0),
            NSPoint(x: 118.0, y: 8.0),
            NSPoint(x: 149.0, y: -1.0),
            NSPoint(x: 181.0, y: -2.0),
            NSPoint(x: 211.0, y: -0.0),
            NSPoint(x: 245.0, y: 1.0),
            NSPoint(x: 281.0, y: 12.0),
            NSPoint(x: 319.0, y: 23.0)
        ]
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
    
    func reset() {
        for hud in huds {
            hud.alphaValue = 0.0
            hud.frame = NSRect.zero
        }
    }
    
    func update(entities: [Entity], cardCount: Int) {
        for (i, hud) in huds.enumerate() {
            var hide = true
            if let entity = entities.firstWhere({ $0.getTag(.ZONE_POSITION) == i + 1 }) {
                hud.entity = entity
                
                var pos: NSPoint? = nil
                if let points = positions[cardCount] where points.count > i {
                    pos = points[i]
                    
                    if let pos = pos {
                        hide = false
                        let rect = NSRect(x: pos.x * SizeHelper.hearthstoneWindow.scaleX,
                                          y: pos.y * SizeHelper.hearthstoneWindow.scaleY,
                                          width: 36,
                                          height: 45)
                        
                        hud.needsDisplay = true
                        
                        // this will avoid a weird move
                        if hud.frame == NSRect.zero {
                            hud.frame = rect
                        }
                        
                        NSAnimationContext.runAnimationGroup({ (context) in
                            context.duration = 0.5
                            hud.animator().frame = rect
                            hud.animator().alphaValue = 1.0
                            }, completionHandler: nil)
                    }
                }
            }
            
            if hide {
                NSAnimationContext.runAnimationGroup({ (context) in
                    context.duration = 0.5
                    hud.animator().alphaValue = 0.0
                    }, completionHandler: nil)
            }
        }
    }
}