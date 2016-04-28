//
//  OpponentCount.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 31/03/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Cocoa

class CardCounter: TextFrame {
    
    private let frameRect = NSMakeRect(0, 0, CGFloat(kFrameWidth), 40)
    private let handFrame = NSMakeRect(60, 11, 68, 25)
    private let deckFrame = NSMakeRect(154, 11, 68, 25)
    
    var handCount = 30
    var deckCount = 0
    
    override func drawRect(dirtyRect: NSRect) {
        super.drawRect(dirtyRect)
        
        addImage(ImageCache.asset("card-counter-frame"), frameRect)
        addInt(handCount, handFrame)
        addInt(deckCount, deckFrame)
    }
}
