//
//  Record.swift
//  HSTracker
//
//  Created by Jon Nguy on 6/5/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation

class StringTracker: TextFrame {
    private let frameRect = NSRect(x: 0, y: 0, width: CGFloat(kFrameWidth), height: 40)
    private let textRect = NSRect(x: 10, y: 1, width: CGFloat(kFrameWidth) - 20, height: 25)

    var message: String = ""

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        add(image: "text-frame.png", rect: frameRect)
        add(string: message, rect: textRect, alignment: .center)
    }
}
