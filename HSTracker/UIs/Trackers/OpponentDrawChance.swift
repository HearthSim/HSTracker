//
//  CountTextCellView.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 6/03/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Cocoa

class OpponentDrawChance: TextFrame {
    
    private let frameRect = NSMakeRect(0, 0, CGFloat(kFrameWidth), 71)
    private let draw1Frame = NSMakeRect(70, 42, 68, 25)
    private let draw2Frame = NSMakeRect(148, 42, 68, 25)
    private let hand1Frame = NSMakeRect(70, 11, 68, 25)
    private let hand2Frame = NSMakeRect(148, 11, 68, 25)

    var drawChance1 = 0.0
    var drawChance2 = 0.0
    var handChance1 = 0.0
    var handChance2 = 0.0
    
    override func drawRect(dirtyRect: NSRect) {
        super.drawRect(dirtyRect)
        
        addImage(ImageCache.asset("opponent-chance-frame"), frameRect)
        addDouble(drawChance1, draw1Frame)
        addDouble(drawChance2, draw2Frame)
        addDouble(handChance1, hand1Frame)
        addDouble(handChance2, hand2Frame)
    }
}