//
//  JadeCounter.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 22/12/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation

class JadeCounter: TextFrame {

    private let frameRect = NSRect(x: 0, y: 0, width: CGFloat(kFrameWidth), height: 40)
    private let draw1Frame = NSRect(x: 70, y: 1, width: 68, height: 25)
    private let draw2Frame = NSRect(x: 148, y: 1, width: 68, height: 25)

    var nextJade = 0

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        add(image: "player-jade-frame.png", rect: frameRect)
        add(int: nextJade, rect: draw1Frame)
        add(int: nextJade, rect: draw2Frame)
    }
}
