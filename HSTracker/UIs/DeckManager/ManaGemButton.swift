//
//  ManaGemButton.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 14/04/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import TextAttributes

class ManaGemButtonCell: NSButtonCell {
    override func drawTitle(title: NSAttributedString,
                            withFrame frame: NSRect,
                                      inView controlView: NSView) -> NSRect {
        return super.drawTitle(title,
                               withFrame: NSRect(x: 2, y: -4, width: 28, height: 32),
                               inView: controlView)
    }
}

class ManaGemButton: NSButton {
    var selected: Bool = false {
        willSet(value) {
            self.image = value ? ImageCache.asset("mana-selected") : ImageCache.asset("mana-dark")
        }
    }

    @IBInspectable var textColor: NSColor = NSColor.whiteColor()

    override func awakeFromNib() {
        super.awakeFromNib()

        let attributes = TextAttributes()
            .alignment(.Center)
            .font(NSFont(name: "Belwe Bd BT", size: 20))
            .foregroundColor(textColor)
            .strokeWidth(-2)
            .strokeColor(NSColor.blackColor())
        self.attributedTitle = NSAttributedString(string: self.title, attributes: attributes)
    }
}
