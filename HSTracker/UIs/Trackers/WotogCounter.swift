//
//  CthunCounter.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 28/04/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation

enum WotogCounterStyle {
    case None,
    Full,
    Cthun,
    Spells
}

class WotogCounter: TextFrame {
    private let frameRect = NSMakeRect(0, 0, CGFloat(kFrameWidth), 40)
    private let attackFrame = NSMakeRect(60, 11, 68, 25)
    private let healthFrame = NSMakeRect(140, 11, 68, 25)
    
    var attack = 6
    var health = 6
    var spell = 0
    var counterStyle = WotogCounterStyle.Full
    
    override func drawRect(dirtyRect: NSRect) {
        super.drawRect(dirtyRect)
        NSLog("coucou \(dirtyRect)")
        
        var frame = frameRect
        var textFrame = attackFrame
        if counterStyle == .Full || counterStyle == .Cthun {
            addImage(ImageCache.asset("cthun-frame"), frame)
            frame = frameRect.offsetBy(dx: 0, dy: NSHeight(frame))
            addInt(attack, textFrame)
            textFrame.origin.y += NSHeight(frame)
            addInt(health, healthFrame)
        }
        if counterStyle == .Full || counterStyle == .Spells {
            addImage(ImageCache.asset("yogg-frame"), frame)
            addInt(spell, textFrame)
        }
    }
}