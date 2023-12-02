//
//  BattlegroundsTierOverlayView.swift
//  HSTracker
//
//  Created by Martin BONNIN on 04/01/2020.
//  Copyright © 2020 Benjamin Michotte. All rights reserved.
//

import Foundation

class BattlegroundsTierOverlayView: NSView {
    var currentTier = 0
    var hoverTier = 0
    var showing = false
    var availableTiers: [Bool] = [false, false, false, false, false, false, false]

    init() {
        super.init(frame: NSRect.zero)
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func isTier7Available() -> Bool {
        return availableTiers[6]
    }
    
    func unhideTier() {
        if !showing {
            let anomalyDbfId =  BattlegroundsUtils.getBattlegroundsAnomalyDbfId(game: AppDelegate.instance().coreManager.game.gameEntity)
            let anomalyCardId = Cards.by(dbfId: anomalyDbfId, collectible: false)?.id
            let availableTiers = BattlegroundsUtils.getAvailableTiers(anomalyCardId: anomalyCardId)
            for i in 1...7 {
                self.availableTiers[i-1] = false
            }
            for tier in availableTiers {
                self.availableTiers[tier-1] = true
            }
            showing = true
        }
        if currentTier >= 1 && currentTier <= 7 {
            let windowManager = AppDelegate.instance().coreManager.game.windowManager
            let controller = windowManager.battlegroundsTierDetailsWindowController
            let frame = SizeHelper.battlegroundsTierDetailFrame()
            controller.detailsView?.contentFrame = frame
            windowManager.show(controller: controller, show: true, frame: frame, overlay: true)
        }
    }
    
    func hideTier() {
        if currentTier >= 1 && currentTier <= 7 {
            let windowManager = AppDelegate.instance().coreManager.game.windowManager
            let controller = windowManager.battlegroundsTierDetailsWindowController
            windowManager.show(controller: controller, show: false)
        }
        showing = false
    }
    
    func reset() {
        hideTier()
        currentTier = 0
        hoverTier = 0
        needsDisplay = true
    }
    
    func drawTier(tier: Int, x: Int) {
        guard let rp = Bundle.main.resourcePath else {
            return
        }
        if hoverTier != 0 && tier == hoverTier || hoverTier == 0 && tier == currentTier {
            let rect = NSRect(x: x, y: 8, width: 40, height: 40)
            if let image = NSImage(contentsOfFile: "\(rp)/Resources/Battlegrounds/tier-glow.png") {
                image.draw(in: rect)
            }
        }

        let rect = NSRect(x: x + 2, y: 10, width: 36, height: 36)
        if let image = NSImage(contentsOfFile: "\(rp)/Resources/Battlegrounds/tier-\(tier).png") {
            image.draw(in: rect, from: NSRect(origin: CGPoint(x: 0, y: 0), size: image.size), operation: .sourceOver, fraction: hoverTier == tier ? (availableTiers[tier - 1] ? 1.0 : 0.6) : (availableTiers[tier - 1] ? 1.0 : 0.3))
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        let backgroundColor: NSColor = NSColor(red: 35/255.0, green: 39/255.0, blue: 42/255.0, alpha: 1.0)
        backgroundColor.set()
        dirtyRect.fill()
        
        let tiers = isTier7Available() ? 7 : 6
        
        for i in 1...tiers {
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

    func displayTier(tier: Int, force: Bool = false) {
        if tier != currentTier || force {
            currentTier = tier
            
            let windowManager = AppDelegate.instance().coreManager.game.windowManager
            let controller = windowManager.battlegroundsTierDetailsWindowController
            if tier >= 1 && tier <= 7 {
                let frame = SizeHelper.battlegroundsTierDetailFrame()
                windowManager.show(controller: controller, show: true,
                                   frame: frame, overlay: true)
                controller.detailsView?.contentFrame = frame
                controller.detailsView?.setTier(tier: tier)
            } else {
                windowManager.show(controller: controller, show: false)
            }
        }
    }
    
    override func mouseUp(with event: NSEvent) {
        guard event.locationInWindow.x.isFinite else {
            return
        }
        let index = (Int(CGFloat(event.locationInWindow.x - 4.0))) / 48 + 1
        let tiers = isTier7Available() ? 7 : 6
        if index >= 1 && index <= tiers {
            displayTier(tier: index == currentTier ? 0 : index)
        } else {
            displayTier(tier: 0)
        }
        needsDisplay = true
    }

    override func mouseMoved(with event: NSEvent) {
        guard event.locationInWindow.x.isFinite else {
            return
        }
        let index = (Int(CGFloat(event.locationInWindow.x - 4.0))) / 48 + 1
        let tiers = isTier7Available() ? 7 : 6

        if index >= 1 && index <= tiers {
            hoverTier = index
        } else {
            hoverTier = 0
        }
        needsDisplay = true
    }

    override func mouseExited(with event: NSEvent) {
        hoverTier = 0
        needsDisplay = true
    }
}
