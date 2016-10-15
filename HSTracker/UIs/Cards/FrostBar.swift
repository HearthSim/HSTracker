//
//  FrostBar.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 31/05/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation

class FrostBar: CardBar {
    override var themeDir: String {
        return "frost"
    }

    override var flashColor: NSColor {
        return NSColor(red: 0.41, green: 0.65, blue: 0.88, alpha: 1.00)
    }

    override func addCardImage() {
        addCardImage(rect: imageRect.offsetBy(dx: -1, dy: 0), offsetByCountBox: false)
    }

    override func addCountText() {
        addCountText(countTextRect.offsetBy(dx: 1, dy: 0))
    }

    override func addLegendaryIcon() {
        addLegendaryIcon(rect: boxRect.offsetBy(dx: -1, dy: 0))
    }
}
