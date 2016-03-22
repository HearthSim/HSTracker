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
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .Center
        
        textField.attributedStringValue = NSAttributedString(string: str, attributes: [
            NSFontAttributeName: NSFont(name: "Belwe Bd BT", size: 14)!,
            NSForegroundColorAttributeName: NSColor.whiteColor(),
            NSStrokeWidthAttributeName: -2,
            NSStrokeColorAttributeName: NSColor.blackColor(),
            NSParagraphStyleAttributeName: paragraph
            ])
    }
}