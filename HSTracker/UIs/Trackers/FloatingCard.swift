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

    @IBOutlet weak var image: NSImageView!
    @IBOutlet weak var drawchancetoplabel: NSTextField!
    @IBOutlet weak var drawchancetop2label: NSTextField!
    
    let attributes = TextAttributes()
    
    override func windowDidLoad() {
        attributes
            .font(NSFont(name: "Belwe Bd BT", size: 13))
            .foregroundColor(.black)
            //.strokeWidth(-1.5)
            .strokeColor(.black)
            .alignment(.center)

        super.windowDidLoad()
    }

    func set(card: Card) {
        image.image = ImageUtils.image(for: card)
    }
    
    func setDrawChanceTop(chance: Float) {
        drawchancetoplabel.attributedStringValue =
            NSAttributedString(string: "\(String(format: "Top deck: %.2f", chance))%",
            attributes: attributes)
    }
    
    func setDrawChanceTop2(chance: Float) {
        drawchancetop2label.attributedStringValue =
            NSAttributedString(string: "\(String(format: "In top 2: %.2f", chance))%",
            attributes: attributes)
    }
}
