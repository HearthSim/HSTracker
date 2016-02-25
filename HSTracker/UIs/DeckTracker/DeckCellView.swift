//
//  DeckCellView.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 24/02/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation

protocol DeckCellViewDelegate {
    func moreClicked(cell:DeckCellView)
}

class DeckCellView: NSView {
    
    @IBOutlet weak var image: NSImageView!
    @IBOutlet weak var label: NSTextField!
    @IBOutlet weak var moreButton: NSButton!
    
    var deck: Deck?
    var color: NSColor?
    var delegate: DeckCellViewDelegate?

    override func drawRect(dirtyRect: NSRect) {
        if let color = color {
            color.set()
            NSRectFill(dirtyRect)
        }
        super.drawRect(dirtyRect)
    }
    
    func setDelegate(delegate: DeckCellViewDelegate?) {
        self.delegate = delegate
    }
    
    @IBAction func action(sender: AnyObject) {
        if let delegate = delegate {
            delegate.moreClicked(self)
        }
    }
}