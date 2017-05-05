//
//  NSImage.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 5/05/17.
//  Copyright © 2017 Benjamin Michotte. All rights reserved.
//

import Foundation

extension NSImage {
    convenience init?(named: String, size: NSSize) {
        guard let image = NSImage(named: named) else { return nil }
        let newImage = NSImage(size: size)

        newImage.lockFocus()
        image.draw(in: NSRect(x: 0, y: 0, width: size.width, height: size.height),
                   from: NSRect.zero,
                   operation: .copy,
                   fraction: 1.0)

        newImage.unlockFocus()
        newImage.size = size
        guard let data = newImage.tiffRepresentation else { return nil }

        self.init(data: data)
    }

    func resized(to size: NSSize) -> NSImage? {
        let newImage = NSImage(size: size)

        newImage.lockFocus()
        draw(in: NSRect(x: 0, y: 0, width: size.width, height: size.height),
             from: NSRect.zero,
             operation: .copy,
             fraction: 1.0)

        newImage.unlockFocus()
        newImage.size = size

        return newImage
    }
}
