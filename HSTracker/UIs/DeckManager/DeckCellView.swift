//
//  DeckCellView.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 24/02/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import AppKit

class DeckCellView: NSView {

    @IBOutlet weak var image: NSImageView!
    @IBOutlet weak var arenaImage: NSImageView!
    @IBOutlet weak var label: NSTextField!
    @IBOutlet weak var moreButton: NSButton!
    @IBOutlet weak var detailTextLabel: NSTextField!
    @IBOutlet weak var wildImage: NSImageView!
    var selected = true

    var deck: Deck?
    var color: NSColor?

    override func draw(_ dirtyRect: NSRect) {
        if var color = color {
            if !selected {
                color = color.darken(amount: 0.50)
            }
            color.set()
            dirtyRect.fill()
        }
        super.draw(dirtyRect)
    }

}
