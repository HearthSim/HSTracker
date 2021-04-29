//
//  TurnCounter.swift
//  HSTracker
//
//  Created by Francisco Moraes on 10/6/20.
//  Copyright © 2020 Benjamin Michotte. All rights reserved.
//

import Foundation

class VerticallyAlignedTextFieldCell: NSTextFieldCell {
    override func drawingRect(forBounds rect: NSRect) -> NSRect {
        let newRect = NSRect(x: 0, y: (rect.size.height - 22) / 2, width: rect.size.width, height: 22)
        return super.drawingRect(forBounds: newRect)
    }
}

class TurnCounter: OverWindowController {

    @objc dynamic var turnLabel = ""

    override func windowDidLoad() {
        super.windowDidLoad()
        
        turnLabel = ""
    }
 
    func setTurnNumber(turn: Int) {
        guard Settings.showTurnCounter else {
            turnLabel = ""
            return
        }

        turnLabel = String(format: "Turn %d", turn)
    }
}
