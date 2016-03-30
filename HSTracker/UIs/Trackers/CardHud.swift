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

    var entity: CardEntity?

    @IBOutlet weak var label: NSTextFieldCell!
    @IBOutlet weak var icon: NSImageView!
    
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
        var image: String? = nil

        if let entity = entity {
            text += "\(entity.turn)"
            //Log.verbose?.message("turn : \(entity.info.turn), mark: \(entity.info.cardMark), cardId : \(entity.cardId)")

            switch entity.cardMark {
            case .Coin: image = "coin"
            case .Kept: image = "kept"
            case .Mulliganed: image = "mulliganed"
            case .Returned: image = "returned"
            case .Created: image = "created"
            default: break
            }
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
        if let image = image {
            icon.image = ImageCache.asset(image)
        }
        else {
            icon.image = nil
        }
    }
}