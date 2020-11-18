//
//  BattlegroundsTierOverlayView.swift
//  HSTracker
//
//  Created by Martin BONNIN on 04/01/2020.
//  Copyright © 2020 Benjamin Michotte. All rights reserved.
//

import Foundation

class BattlegroundsTierOverlayView: NSView {
    var currentTier = -1

    init() {
        super.init(frame: NSRect.zero)
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func drawTier(tier: Int, x: Int) {
        if tier == currentTier {
            let rect = NSRect(x: x, y: 8, width: 40, height: 40)
            let image = NSImage(contentsOfFile: Bundle.main.resourcePath! + "/Resources/Battlegrounds/tier-glow.png")!
            image.draw(in: rect)
        }

        let rect = NSRect(x: x + 2, y: 10, width: 36, height: 36)
        let image = NSImage(contentsOfFile: Bundle.main.resourcePath! + "/Resources/Battlegrounds/tier-\(tier).png")!
        image.draw(in: rect)
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        let backgroundColor: NSColor = NSColor(red: 35/255.0, green: 39/255.0, blue: 42/255.0, alpha: 1.0)
        backgroundColor.set()
        dirtyRect.fill()
        
        for i in 1...6 {
            drawTier(tier: i, x: 8 + (i - 1) * 48)
        }
    }
    
    private lazy var trackingArea: NSTrackingArea = NSTrackingArea(rect: NSRect.zero,
                                                                   options: [.inVisibleRect, .activeAlways, .mouseEnteredAndExited, .mouseMoved],
                              owner: self,
                              userInfo: nil)

    override func updateTrackingAreas() {
        super.updateTrackingAreas()

        if !self.trackingAreas.contains(trackingArea) {
            self.addTrackingArea(trackingArea)
        }
    }

    func displayTier(tier: Int) {
        if tier != currentTier {
            currentTier = tier
            setNeedsDisplay(frame)
            
            let windowManager = AppDelegate.instance().coreManager.game.windowManager
            let controller = windowManager.battlegroundsTierDetailsWindowController
            if tier >= 1 && tier <= 6 {
                
                windowManager.show(controller: controller, show: true,
                                   frame: SizeHelper.battlegroundsTierDetailFrame(), overlay: true)
                controller.setTier(tier: tier)
            } else {
                windowManager.show(controller: controller, show: false)
            }
        }
    }

    override func mouseMoved(with event: NSEvent) {
        let index = (Int(CGFloat(event.locationInWindow.x - 4.0))) / 48 + 1
        
        displayTier(tier: index)
    }

    override func mouseEntered(with event: NSEvent) {
    }

    override func mouseExited(with event: NSEvent) {
        displayTier(tier: -1)
    }
}
