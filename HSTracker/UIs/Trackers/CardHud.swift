//
//  CardHud.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 12/03/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation

class CardHud : NSWindowController {
    var position: Int = 0
    var entity: CardEntity?

    @IBOutlet weak var label: NSTextFieldCell!

    override func windowDidLoad() {
        super.windowDidLoad()

        self.window!.styleMask = NSBorderlessWindowMask
        self.window!.ignoresMouseEvents = true
        self.window!.level = Int(CGWindowLevelForKey(CGWindowLevelKey.ScreenSaverWindowLevelKey))

        self.window!.opaque = false
        self.window!.hasShadow = false
        self.window!.backgroundColor = NSColor(red: 0, green: 0, blue: 0, alpha: 0)
    }

    func setEntity(entity: CardEntity?) {
        self.entity = entity
        var text = ""

        if let entity = entity {
            text += "\(entity.turn)"

            switch entity.cardMark {
            case .Coin:
                label.stringValue += "C"

            case .Kept:
                label.stringValue += "K"

            case .Mulliganed:
                label.stringValue += "M"

            case .Returned:
                label.stringValue += "R"

            case .Created:
                label.stringValue += "Cr"

            default: break
            }
        }
        label.stringValue = text
    }
}