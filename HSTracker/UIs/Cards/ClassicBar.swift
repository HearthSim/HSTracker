//
//  ClassicBar.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 31/05/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation

class ClassicBar: CardBar {
    private let _fadeRect = NSRect(x: 28, y: 0, width: 189, height: 34)
    private let _imageRect = NSRect(x: 108, y: 4, width: 108, height: 27)
    private let _costRect = NSRect(x: 1, y: -13, width: 34, height: 37)

    override var textFont: String {
        if Settings.isAsianLanguage {
            return "NanumGothic"
        } else if Settings.isCyrillicLanguage {
            return "Benguiat Rus"
        } else {
            return "Belwe Bd BT"
        }
    }

    override var flashColor: NSColor {
        return NSColor(red: 1, green: 0.647, blue: 0, alpha: 1)
    }

    override var themeDir: String {
        return "classic"
    }

    override func initVars() {
        imageOffset = -19
        fadeOffset = -19
        createdIconOffset = -19
        textFontSize = 18
    }

    override func addCardName() {
        addCardName(rect: NSRect(x: 38,
            y: 10,
            width: frameRect.width - boxRect.width - 38,
            height: 30))
    }

    override func addFadeOverlay() {
        addFadeOverlay(rect: _fadeRect, offsetByCountBox: true)
    }

    override func addCardImage() {
        addCardImage(rect: _imageRect, offsetByCountBox: true)
    }

    override func addCost() {
        addCost(rect: costTextRect.offsetBy(dx: 1, dy: 0))
    }
}
