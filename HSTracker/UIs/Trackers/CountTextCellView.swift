//
//  CountTextCellView.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 6/03/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Cocoa

class CountTextCellView: NSView {

    @IBOutlet weak var textField: NSTextField!

    func setText(str: String) {
        textField.stringValue = str
    }

    /*override func drawRect(dirtyRect: NSRect) {
     super.drawRect(dirtyRect)

     if let text = _text {
     var ratio: Double
     switch Settings.instance.cardSize {
     case .Small: ratio = kRowHeight / kSmallRowHeight
     case .Medium: ratio = kRowHeight / kMediumFrameWidth
     default: ratio = 1.0
     }

     let fontSize = CGFloat(round(14.0 / ratio))
     let style = NSMutableParagraphStyle()
     style.alignment = NSCenterTextAlignment
     let name = NSAttributedString(string: text,
     attributes: [
     NSParagraphStyleAttributeName: style,
     NSForegroundColorAttributeName: NSColor.whiteColor(),
     NSFontAttributeName: NSFont(name: "Belwe Bd BT", size: fontSize)!,
     NSStrokeWidthAttributeName: -1.5,
     NSStrokeColorAttributeName: NSColor.blackColor()
     ])
     name.drawInRect(NSMakeRect(0.0, CGFloat(-3.0 / ratio), CGFloat(220.0 / ratio), CGFloat(50.0 / ratio)),
     options: [.UsesLineFragmentOrigin | .UsesDeviceMetrics])
     }
     }*/
}