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
    deathrattles,
    libram
}

class WotogCounterFrame: TextFrame {
    private let frameRect = NSRect(x: 0, y: 0, width: CGFloat(kFrameWidth), height: 40)
    private let attackFrame = NSRect(x: 60, y: 1, width: 68, height: 25)
    private let healthFrame = NSRect(x: 140, y: 1, width: 68, height: 25)

    var attack = 6
    var health = 6
    var spell = 0
    var deathrattle = 0
    var libram = 0
    var counterStyle: [WotogCounterStyle] = [.full]

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        var frame = frameRect
        var textFrame = attackFrame
        if counterStyle.contains(.full) || counterStyle.contains(.cthun) {
            add(image: "cthun-frame.png", rect: frame)
            add(int: attack, rect: textFrame)
            add(int: health, rect: healthFrame)

            frame = frame.offsetBy(dx: 0, dy: frame.height)
            textFrame.origin.y += frame.height
        }
        if counterStyle.contains(.full) || counterStyle.contains(.spells) {
            add(image: "yogg-frame.png", rect: frame)
            add(int: spell, rect: textFrame)

            frame = frame.offsetBy(dx: 0, dy: frame.height)
            textFrame.origin.y += frame.height
        }
        if counterStyle.contains(.full) || counterStyle.contains(.deathrattles) {
            add(image: "deathrattle-frame.png", rect: frame)
            add(int: deathrattle, rect: textFrame)
            frame = frame.offsetBy(dx: 0, dy: frame.height)
            textFrame.origin.y += frame.height
        }
        
        if counterStyle.contains(.full) || counterStyle.contains(.libram) {
            add(image: "libram-frame.png", rect: frame)
            add(int: libram, rect: textFrame)
        }
    }
}
