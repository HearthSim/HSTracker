//
//  CardHud.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 12/03/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import CleanroomLogger

class CardHud : NSWindowController {

    var entity: Entity?

    @IBOutlet weak var label: NSTextFieldCell!
    @IBOutlet weak var icon: NSImageView!
    @IBOutlet weak var costReduction: NSTextField!
    
    override func windowDidLoad() {
        super.windowDidLoad()

        self.window!.styleMask = NSBorderlessWindowMask
        self.window!.ignoresMouseEvents = true
        self.window!.level = Int(CGWindowLevelForKey(CGWindowLevelKey.ScreenSaverWindowLevelKey))

        self.window!.opaque = false
        self.window!.hasShadow = false
        self.window!.backgroundColor = NSColor(red: 0, green: 0, blue: 0, alpha: 0)
    }

    func setEntity(entity: Entity?) {
        self.entity = entity
        var text = ""
        var image: String? = nil
        var cost = 0

        if let entity = entity {
            text += "\(entity.info.turn)"

            switch entity.info.cardMark {
            case .Coin: image = "coin"
            case .Kept: image = "kept"
            case .Mulliganed: image = "mulliganed"
            case .Returned: image = "returned"
            case .Created: image = "created"
            default: break
            }
            cost = entity.info.costReduction
        }
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .Center
        label.attributedStringValue = NSAttributedString(string: text, attributes: [
            NSFontAttributeName: NSFont(name: "Belwe Bd BT", size: 20)!,
            NSForegroundColorAttributeName: NSColor.whiteColor(),
            NSStrokeWidthAttributeName: -2,
            NSStrokeColorAttributeName: NSColor.blackColor(),
            NSParagraphStyleAttributeName: paragraph
            ])
        costReduction.attributedStringValue = NSAttributedString(string: "-\(cost)", attributes: [
            NSFontAttributeName: NSFont(name: "Belwe Bd BT", size: 16)!,
            NSForegroundColorAttributeName: NSColor(red: 0.117, green: 0.56, blue: 1, alpha: 1),
            NSStrokeWidthAttributeName: -2,
            NSStrokeColorAttributeName: NSColor.blackColor()
            ])
        costReduction.hidden = cost < 1
        if let image = image {
            icon.image = ImageCache.asset(image)
        }
        else {
            icon.image = nil
        }
    }
}