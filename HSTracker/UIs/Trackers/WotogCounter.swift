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
    private let frameRect = NSRect(x: 0, y: 0, width: CGFloat(kFrameWidth), height: 40)
    private let attackFrame = NSRect(x: 60, y: 11, width: 68, height: 25)
    private let healthFrame = NSRect(x: 140, y: 11, width: 68, height: 25)

    var attack = 6
    var health = 6
    var spell = 0
    var counterStyle = WotogCounterStyle.Full

    override func drawRect(dirtyRect: NSRect) {
        super.drawRect(dirtyRect)

        var frame = frameRect
        var textFrame = attackFrame
        if counterStyle == .Full || counterStyle == .Cthun {
            addImage(ImageCache.asset("cthun-frame"), rect: frame)
            frame = frameRect.offsetBy(dx: 0, dy: NSHeight(frame))
            addInt(attack, rect: textFrame)
            textFrame.origin.y += NSHeight(frame)
            addInt(health, rect: healthFrame)
        }
        if counterStyle == .Full || counterStyle == .Spells {
            addImage(ImageCache.asset("yogg-frame"), rect: frame)
            addInt(spell, rect: textFrame)
        }
    }
}
