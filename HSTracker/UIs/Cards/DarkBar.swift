//
//  DardBar.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 31/05/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation

class DarkBar: CardBar {
    private var _fadeRect = NSRect(x: 34, y: 0, width: 183, height: 34)

    override var themeDir: String {
        return "dark"
    }

    override var flashColor: NSColor {
        return NSColor(red: 0.1922, green: 0.5255, blue: 0.8706, alpha: 1.0)
    }

    override func addFadeOverlay() {
        addFadeOverlay(rect: _fadeRect, offsetByCountBox: true)
    }

    override func addCardImage() {
        addCardImage(rect: imageRect, offsetByCountBox: true)
    }

    override func addCountText() {
        addCountText(countTextRect.offsetBy(dx: 2, dy: 0))
    }
}
