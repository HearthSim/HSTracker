//
//  BorderView.swift
//  HSTracker
//
//  Created by Martin BONNIN on 05/05/2020.
//  Copyright © 2020 Benjamin Michotte. All rights reserved.
//

import Foundation

@IBDesignable
class FrameView: NSView {
    var color = NSColor.black
    var frameWidth = 2
    
    init() {
        super.init(frame: NSRect.zero)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func draw(_ dirtyRect: NSRect) {
        color.set()
        dirtyRect.frame(withWidth: CGFloat(frameWidth))
    }
}
