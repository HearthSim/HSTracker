//
//  GraveyardCounter.swift
//  HSTracker
//
//  Created by Istvan Fehervari on 25/09/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import AppKit

class GraveyardCounter: TextFrame {
    
    var cardHeight: CGFloat = CGFloat(kMediumRowHeight)
    private let frameRect = NSRect(x: 0, y: 0, width: CGFloat(kFrameWidth), height: 40)
    private let firstNumberFrame = NSRect(x: 60, y: 1, width: 68, height: 25)
    private let secondNumberFrame = NSRect(x: 158, y: 1, width: 68, height: 25)
    private var graveyardinitialized: Bool = false
    var displayDetails: Bool = true
    
    var graveyard: [Card] = []
    var minions: Int = 0
    var murlocks: Int = 0
    private var graveyardWindow: CardList?
    private var trackingArea: NSTrackingArea?
    var playerType: PlayerType = PlayerType.cardList
    
    private func initGraveyard() {
        graveyardWindow = CardList(windowNibName: "CardList")
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        if !graveyardinitialized {
            self.initGraveyard()
            graveyardinitialized = true
        }
        
        add(image: "graveyard-frame.png", rect: frameRect)
        add(int: minions, rect: firstNumberFrame)
        add(int: murlocks, rect: secondNumberFrame)
        
        for trackingArea in self.trackingAreas {
            self.removeTrackingArea(trackingArea)
        }
        
        if displayDetails {
            let trackingarea = NSTrackingArea(rect: frameRect,
                                              options: [NSTrackingArea.Options.mouseEnteredAndExited,
                                                NSTrackingArea.Options.activeAlways, NSTrackingArea.Options.inVisibleRect],
                                              owner: self, userInfo: nil)
            self.addTrackingArea(trackingarea)
        }
    }
    
    override func mouseEntered(with theEvent: NSEvent) {
        
        self.updateGraveyard()
        var point = theEvent.locationInWindow
        
        // show graveyard
        let gframe = self.window!.frame
        if let gw = graveyardWindow {
            if let screenpoint = self.window?.convertToScreen(
                NSRect(x: point.x, y: point.y, width: 0, height: 0)) {
                point.x = playerType == .player ? gframe.minX - gframe.width : gframe.maxX
                point.y = screenpoint.origin.y
            }

            let frame = NSRect(x: point.x, y: point.y, width: gframe.width, height: gw.frameHeight)
            AppDelegate.instance().coreManager.game.windowManager.show(controller: gw, show: true, frame: frame, overlay: true)
        }
    }
    
    override func mouseExited(with theEvent: NSEvent) {
        // hide graveyard
        if let gw = graveyardWindow {
            AppDelegate.instance().coreManager.game.windowManager.show(controller: gw, show: false)
        }
    }
    
    private func updateGraveyard() {
        
        if let gw = graveyardWindow {
            gw.set(cards: graveyard)
            gw.setWindowSizes()
        }
    }
}
