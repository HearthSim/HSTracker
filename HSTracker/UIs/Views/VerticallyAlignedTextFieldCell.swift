//
//  VerticallyAlignedTextFieldCell.swift
//  HSTracker
//
//  Created by Francisco Moraes on 11/8/21.
//  Copyright © 2021 Benjamin Michotte. All rights reserved.
//

import Foundation

class VerticallyAlignedTextFieldCell: NSTextFieldCell {

    override func drawingRect(forBounds rect: NSRect) -> NSRect {
        let textSize: NSSize = self.cellSize(forBounds: rect)
        let newRect = NSRect(x: 0, y: (rect.size.height - textSize.height) / 2, width: rect.size.width, height: textSize.height)
        return newRect
    }
}
