//
//  FloatingCard.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 7/04/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation

class FloatingCard: NSWindowController {

    @IBOutlet weak var image: NSImageView!

    override func windowDidLoad() {
        super.windowDidLoad()

        self.window!.ignoresMouseEvents = true
        self.window!.acceptsMouseMovedEvents = true
        self.window!.level = Int(CGWindowLevelForKey(CGWindowLevelKey.screenSaverWindow))
        self.window!.backgroundColor = NSColor.clear
    }

    func set(card: Card) {
        image.image = ImageUtils.image(for: card)
    }
}
