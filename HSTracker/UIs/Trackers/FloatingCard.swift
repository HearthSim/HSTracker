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

    @IBOutlet weak var imageView: NSImageView!

    var card: Card?
    var isBattlegrounds = false

    func set(card: Card) {
        self.card = card
        reload()
    }

    private func reload() {
        if let cardId = self.card?.id, let lang = Settings.hearthstoneLanguage?.rawValue {
            let imageUrl = URL(string: isBattlegrounds ? ImageUtils.artUrlBG(cardId: cardId, lang: lang) : ImageUtils.artUrl(cardId: cardId, lang: lang))!
            self.imageView.kf.setImage(with: imageUrl)
        }

        window?.backgroundColor = NSColor.clear
        imageView.isHidden = false

        // "pack frame"
        if let window = self.window {
            let width = window.frame.size.width
            let totalHeight = width * 250/180
            self.window?.setContentSize(NSSize(width: width,
                    height: totalHeight))
        }
    }
}
