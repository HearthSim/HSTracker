//
//  Record.swift
//  HSTracker
//
//  Created by Jon Nguy on 6/5/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation

class RecordTracker: TextFrame {
    private let frameRect = NSRect(x: 0, y: 0, width: CGFloat(kFrameWidth), height: 40)

    var stats: String = ""

    override func drawRect(dirtyRect: NSRect) {
        super.drawRect(dirtyRect)

        addString(stats, rect: frameRect, alignment: .Center)
    }
}
