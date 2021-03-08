//
//  FloatingCard.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 7/04/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import TextAttributes
import Kingfisher

enum FloatingCardStyle: String {
    case text
    case image
}

class FloatingCard: OverWindowController {

    @IBOutlet weak var title: NSTextField!
    @IBOutlet weak var scrollview: NSScrollView!
    @IBOutlet weak var imageView: NSImageView!

    // for reference http://stackoverflow.com/questions/24062437
    var text: NSTextView? {
        if let scrollview = self.scrollview {
            return scrollview.contentView.documentView as? NSTextView
        }
        return nil
    }

    var card: Card?
    var isBattlegrounds = false
    private var drawChanceTop: Float = 0
    private var drawChanceTop2: Float = 0

    let attributes: TextAttributes = {
        $0.font(NSFont(name: "Belwe Bd BT", size: 13))
            .foregroundColor(.textColor)
            .strokeColor(.textColor)
            .alignment(.center)
        return $0
    }(TextAttributes())

    let titleAttributes: TextAttributes = {
        $0.font(NSFont(name: "Belwe Bd BT", size: 16))
            .foregroundColor(.textColor)
            .strokeColor(.textColor)
            .alignment(.center)
        return $0
    }(TextAttributes())

    func set(card: Card, drawChanceTop: Float, drawChanceTop2: Float) {
        self.drawChanceTop = drawChanceTop
        self.drawChanceTop2 = drawChanceTop2
        self.card = card
        reload()
    }

    func set(drawChanceTop: Float) {
        self.drawChanceTop = drawChanceTop
        reload()
    }

    func set(drawChanceTop2: Float) {
        self.drawChanceTop2 = drawChanceTop2
        reload()
    }

    private func reload() {
        if let cardId = self.card?.id, let lang = Settings.hearthstoneLanguage?.rawValue {
            let imageUrl = URL(string: isBattlegrounds ? ImageUtils.artUrlBG(cardId: cardId, lang: lang) : ImageUtils.artUrl(cardId: cardId, lang: lang))!
            self.imageView.kf.setImage(with: imageUrl)
        }

        if isBattlegrounds {
            title.isHidden = true
            scrollview.isHidden = true
            window?.backgroundColor = NSColor.clear
        } else {
            window?.backgroundColor = NSColor.textBackgroundColor
            title.isHidden = false
            scrollview.isHidden = false
        }
        imageView.isHidden = false

        var information = "\n"
        if let card = card, let title = self.title {
            title.attributedStringValue = NSAttributedString(string: card.name,
                    attributes: titleAttributes)
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
            let flt_max = Float.greatestFiniteMagnitude
            let textContainer = NSTextContainer(containerSize:
            NSSize(width: window.frame.size.width, height: CGFloat(flt_max)))
            layoutManager.addTextContainer(textContainer)
            textStorage.addLayoutManager(layoutManager)

            textContainer.lineFragmentPadding = 0.0
            layoutManager.glyphRange(for: textContainer)
            let textHeight = layoutManager.usedRect(for: textContainer).size.height

            let width = window.frame.size.width
            let totalHeight = textHeight + self.title.frame.size.height + width * 250/180
            self.window?.setContentSize(NSSize(width: width,
                    height: totalHeight))
        }
    }
}
