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
    @IBOutlet weak var text: NSTextField!

    private var card: Card?
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

    func set(card: Card) {
        self.card = card
        reloadText()
    }

    func setDrawChanceTop(chance: Float) {
        drawChanceTop = chance
        reloadText()
    }
    
    func setDrawChanceTop2(chance: Float) {
        drawChanceTop2 = chance
        reloadText()
    }

    private func reloadText() {
        var information = ""
        if let card = card {
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
        text.attributedStringValue = NSAttributedString(string: information,
                                                        attributes: attributes)
    }
}
