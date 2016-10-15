//
//  CountTextCellView.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 6/03/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Cocoa

class OpponentDrawChance: TextFrame {

    private let frameRect = NSRect(x: 0, y: 0, width: CGFloat(kFrameWidth), height: 71)
    private let draw1Frame = NSRect(x: 70, y: 32, width: 68, height: 25)
    private let draw2Frame = NSRect(x: 148, y: 32, width: 68, height: 25)
    private let hand1Frame = NSRect(x: 70, y: 1, width: 68, height: 25)
    private let hand2Frame = NSRect(x: 148, y: 1, width: 68, height: 25)

    var drawChance1 = 0.0
    var drawChance2 = 0.0
    var handChance1 = 0.0
    var handChance2 = 0.0

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        add(image: "opponent-chance-frame.png", rect: frameRect)
        add(double: drawChance1, rect: draw1Frame)
        add(double: drawChance2, rect: draw2Frame)
        add(double: handChance1, rect: hand1Frame)
        add(double: handChance2, rect: hand2Frame)
    }
}
