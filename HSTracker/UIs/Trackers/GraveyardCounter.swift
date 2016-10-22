//
//  GraveyardCounter.swift
//  HSTracker
//
//  Created by Istvan Fehervari on 25/09/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation

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
    private var graveyardWindow: NSWindow?
    private var trackingArea: NSTrackingArea?
    
    private func initGraveyard() {
        graveyardWindow = NSWindow(contentRect:
            NSRect(x: 0, y: 0, width: (self.window?.frame.width)!, height: 800),
                                   styleMask: NSBorderlessWindowMask,
                                   backing: .buffered,
                                   defer: true)
        
        graveyardWindow?.setIsVisible(false)
        graveyardWindow?.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        graveyardWindow?.ignoresMouseEvents = true
        graveyardWindow?.acceptsMouseMovedEvents = true
        graveyardWindow?.level = Int(CGWindowLevelForKey(
            CGWindowLevelKey.screenSaverWindow))
        graveyardWindow?.backgroundColor = NSColor.clear
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
                                              options: [.mouseEnteredAndExited,
                                                .activeAlways, .inVisibleRect],
                                              owner: self, userInfo: nil)
            self.addTrackingArea(trackingarea)
        }
    }
    
    override func mouseEntered(with theEvent: NSEvent) {
        
        self.updateGraveyard()
        var point = theEvent.locationInWindow
        
        // show graveyard
        if let gframe = graveyardWindow?.frame {
            
            if let screenpoint = self.window?.convertToScreen(
                NSRect(x: point.x, y: point.y, width: 0, height: 0)) {
                point.x = min(screenpoint.origin.x,
                              (self.window?.screen?.frame.width)! - gframe.width)
                point.y = max(screenpoint.origin.y, gframe.height)
            }
            
            graveyardWindow?.setFrame(NSRect(
                x: point.x, y: point.y,
                width: gframe.width, height: gframe.height),
                                      display: true)
        }
        
        graveyardWindow?.orderFront(self)
    }
    
    override func mouseExited(with theEvent: NSEvent) {
        // hide graveyard
        graveyardWindow?.orderOut(self)
    }
    
    private func updateGraveyard() {
        
        if let mainView = graveyardWindow?.contentView {
            for view in mainView.subviews {
                view.removeFromSuperview()
            }
            
            if let gframe = graveyardWindow?.frame {
                let height: CGFloat = cardHeight*CGFloat(graveyard.count)
                graveyardWindow?.setFrame(NSRect(
                    x: 0, y: 0,
                    width: gframe.width, height: height),
                                          display: true)
                if graveyard.count > 0 {
                    var y: CGFloat = height
                    for entity in graveyard {
                        y -= cardHeight
                        let cell = CardBar.factory()
                        cell.card = entity
                        cell.frame = NSRect(x: 0, y: y, width: gframe.width, height: cardHeight)
                        mainView.addSubview(cell)
                    }
                }
            }
        }
        
    }
}
