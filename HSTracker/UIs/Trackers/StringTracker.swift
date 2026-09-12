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
    var fontSize: CGFloat = 18
    var showsBackground = true
    var verticallyCentersText = false
    var verticalTextOffset: CGFloat = 0

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        if showsBackground {
            add(image: "text-frame.png", rect: frameRect)
        }
        add(string: message, rect: textRect, alignment: .center, fontSize: fontSize,
            verticallyCentered: verticallyCentersText, verticalOffset: verticalTextOffset)
    }
}
