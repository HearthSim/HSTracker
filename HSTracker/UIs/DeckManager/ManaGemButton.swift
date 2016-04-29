//
//  ManaGemButton.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 14/04/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation

class ManaGemButtonCell: NSButtonCell {
    override func drawTitle(title: NSAttributedString,
                            withFrame frame: NSRect,
                                      inView controlView: NSView) -> NSRect {
        return super.drawTitle(title, withFrame: NSMakeRect(2, -4, 28, 32), inView: controlView)
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

        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .Center

        let style = [
            NSFontAttributeName: NSFont(name: "Belwe Bd BT", size: 20)!,
            NSForegroundColorAttributeName: textColor,
            NSStrokeWidthAttributeName: -2,
            NSStrokeColorAttributeName: NSColor.blackColor(),
            NSParagraphStyleAttributeName: paragraph
        ]
        self.attributedTitle = NSAttributedString(string: self.title, attributes: style)
    }
}
