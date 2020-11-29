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
    override func drawTitle(_ title: NSAttributedString,
                            withFrame frame: NSRect,
                            in controlView: NSView) -> NSRect {
        return super.drawTitle(title,
                               withFrame: NSRect(x: 2, y: -4, width: 28, height: 32),
                               in: controlView)
    }
}

class ManaGemButton: NSButton {
    var selected: Bool = false {
        willSet(value) {
            self.image = value ? NSImage(named: "mana-selected") : NSImage(named: "mana-dark")
        }
    }

    @IBInspectable var textColor: NSColor = NSColor.white

    override func awakeFromNib() {
        super.awakeFromNib()

        let attributes = TextAttributes()
            .alignment(.center)
            .font(NSFont(name: "Belwe Bd BT", size: 20))
            .foregroundColor(textColor)
            .strokeWidth(-2)
            .strokeColor(.black)
        self.attributedTitle = NSAttributedString(string: self.title, attributes: attributes)
    }
}
