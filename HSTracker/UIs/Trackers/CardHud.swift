//
//  CardHud.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 12/03/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation

class CardHud : NSWindowController {

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
            DDLogVerbose("turn : \(entity.turn), mark: \(entity.cardMark), cardId : \(entity.cardId) / \(entity.entity?.cardId)")

            switch entity.cardMark {
            case .Coin:
                text += "C"

            case .Kept:
                text += "K"

            case .Mulliganed:
                text += "M"

            case .Returned:
                text += "R"

            case .Created:
                text += "Cr"

            default: break
            }
        }
        label.attributedStringValue = NSAttributedString(string: text, attributes: [
            NSFontAttributeName: NSFont(name: "Belwe Bd BT", size: 20)!,
            NSForegroundColorAttributeName: NSColor.whiteColor(),
            NSStrokeWidthAttributeName: -2,
            NSStrokeColorAttributeName: NSColor.blackColor()
            ])
    }
}