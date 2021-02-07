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

    @IBOutlet weak var image: NSImageView!
    @IBOutlet weak var arenaImage: NSImageView!
    @IBOutlet weak var label: NSTextField!
    @IBOutlet weak var detailTextLabel: NSTextField!
    @IBOutlet weak var wildImage: NSImageView!
    @IBOutlet weak var useButton: NSButton!
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
