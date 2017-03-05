//
//  FloatingCard.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 7/04/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import TextAttributes

class FloatingCard: OverWindowController {

    @IBOutlet weak var title: NSTextField!
    @IBOutlet weak var scrollview: NSScrollView!

    // for reference http://stackoverflow.com/questions/24062437
    var text: NSTextView? {
        if let scrollview = self.scrollview {
            return scrollview.contentView.documentView as? NSTextView
        }
        return nil
    }

    var card: Card?
    private var drawChanceTop: Float = 0
    private var drawChanceTop2: Float = 0
    
    let attributes: TextAttributes = {
        $0.font(NSFont(name: "Belwe Bd BT", size: 13))
            .foregroundColor(.black)
            .strokeColor(.black)
            .alignment(.center)
        return $0
    }(TextAttributes())

    let titleAttributes: TextAttributes = {
        $0.font(NSFont(name: "Belwe Bd BT", size: 16))
            .foregroundColor(.black)
            .strokeColor(.black)
            .alignment(.center)
        return $0
    }(TextAttributes())

    func set(card: Card, drawChanceTop: Float, drawChanceTop2: Float) {
        self.drawChanceTop = drawChanceTop
        self.drawChanceTop2 = drawChanceTop2
        self.card = card
        reloadText()
    }

    func set(drawChanceTop: Float) {
        self.drawChanceTop = drawChanceTop
        reloadText()
    }
    
    func set(drawChanceTop2: Float) {
        self.drawChanceTop2 = drawChanceTop2
        reloadText()
    }

    private func reloadText() {
        var information = ""
        if let card = card, let title = self.title {
            title.attributedStringValue = NSAttributedString(string: card.name,
                                                             attributes: titleAttributes)
            if !card.text.isEmpty {
                information = card.formattedText() + "\n\n"
            }
        }
        if drawChanceTop > 0 {
            information += NSLocalizedString("Top deck:", comment: "")
                + "\(String(format: " %.2f", drawChanceTop))%\n"
        }
        if drawChanceTop2 > 0 {
            information += NSLocalizedString("In top 2:", comment: "")
                + "\(String(format: " %.2f", drawChanceTop2))%\n"
        }
        text?.string = ""
        text?.textStorage?.append(NSAttributedString(string: information,
                                                        attributes: attributes))
        
        // "pack frame"
        if let window = self.window {
            let layoutManager = NSLayoutManager()
            let textStorage = NSTextStorage(attributedString:
                NSAttributedString(string: information, attributes: attributes))
            let textContainer = NSTextContainer(containerSize:
                NSSize(width: window.frame.size.width, height: CGFloat(FLT_MAX)))
            layoutManager.addTextContainer(textContainer)
            textStorage.addLayoutManager(layoutManager)
            
            textContainer.lineFragmentPadding = 0.0
            layoutManager.glyphRange(for: textContainer)
            let textheight = layoutManager.usedRect(for: textContainer).size.height
            
            self.window?.setContentSize(NSSize(width: window.frame.size.width,
                                               height: self.title.frame.size.height +
                                                    textheight))
        }
        
    }
}
