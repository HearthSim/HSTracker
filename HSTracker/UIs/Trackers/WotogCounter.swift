//
//  CthunCounter.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 28/04/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation

enum WotogCounterStyle {
    case none,
    full,
    cthun,
    spells,
    deathrattles
}

class WotogCounter: TextFrame {
    private let frameRect = NSRect(x: 0, y: 0, width: CGFloat(kFrameWidth), height: 40)
    private let attackFrame = NSRect(x: 60, y: 1, width: 68, height: 25)
    private let healthFrame = NSRect(x: 140, y: 1, width: 68, height: 25)

    var attack = 6
    var health = 6
    var spell = 0
    var deathrattle = 0
    var counterStyle: [WotogCounterStyle] = [.full]

    override func drawRect(dirtyRect: NSRect) {
        super.drawRect(dirtyRect)

        var frame = frameRect
        var textFrame = attackFrame
        if counterStyle.contains(.full) || counterStyle.contains(.cthun) {
            addImage("cthun-frame.png", rect: frame)
            addInt(attack, rect: textFrame)
            addInt(health, rect: healthFrame)

            frame.offsetInPlace(dx: 0, dy: frame.height)
            textFrame.origin.y += frame.height
        }
        if counterStyle.contains(.full) || counterStyle.contains(.spells) {
            addImage("yogg-frame.png", rect: frame)
            addInt(spell, rect: textFrame)

            frame.offsetInPlace(dx: 0, dy: frame.height)
            textFrame.origin.y += frame.height
        }
        if counterStyle.contains(.full) || counterStyle.contains(.deathrattles) {
            addImage("deathrattle-frame.png", rect: frame)
            addInt(deathrattle, rect: textFrame)
        }
    }
}
