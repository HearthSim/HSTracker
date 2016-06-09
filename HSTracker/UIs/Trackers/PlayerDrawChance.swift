//
//  PlayerDrawChance.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 31/03/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation

class PlayerDrawChance: TextFrame {

    private let frameRect = NSRect(x: 0, y: 0, width: CGFloat(kFrameWidth), height: 40)
    private let draw1Frame = NSRect(x: 70, y: 1, width: 68, height: 25)
    private let draw2Frame = NSRect(x: 148, y: 1, width: 68, height: 25)

    var drawChance1 = 0.0
    var drawChance2 = 0.0

    override func drawRect(dirtyRect: NSRect) {
        super.drawRect(dirtyRect)

        addImage("player-chance-frame.png", rect: frameRect)
        addDouble(drawChance1, rect: draw1Frame)
        addDouble(drawChance2, rect: draw2Frame)
    }
}
