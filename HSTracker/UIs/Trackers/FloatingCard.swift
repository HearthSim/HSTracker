//
//  FloatingCard.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 7/04/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation

class FloatingCard: OverWindowController {

    @IBOutlet weak var image: NSImageView!

    func set(card: Card) {
        image.image = ImageUtils.image(for: card)
    }
}
