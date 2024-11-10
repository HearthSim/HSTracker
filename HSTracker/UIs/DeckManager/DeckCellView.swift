//
//  DeckCellView.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 24/02/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import AppKit

class DeckCellView: NSTableCellView {

    @IBOutlet var image: NSImageView!
    @IBOutlet var arenaImage: NSImageView!
    @IBOutlet var label: NSTextField!
    @IBOutlet var detailTextLabel: NSTextField!
    @IBOutlet var wildImage: NSImageView!
    @IBOutlet var useButton: NSButton!
    var selected = true
    var row = -1

    var deck: Deck?
    var color: NSColor?

    override func draw(_ dirtyRect: NSRect) {
        if let color = color {
            if selected {
                NSColor.selectedControlColor.set()
            } else {
                color.set()
            }
            dirtyRect.fill()
        }
        super.draw(dirtyRect)
    }

}
