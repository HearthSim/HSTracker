//
//  NSImage.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 5/05/17.
//  Copyright © 2017 Benjamin Michotte. All rights reserved.
//

import Foundation

extension NSImage {
    convenience init?(named: String, size: NSSize, tintColor: NSColor? = nil) {
        guard let image = NSImage(named: named) else { return nil }
        let newImage = NSImage(size: size)

        newImage.lockFocus()
        image.draw(in: NSRect(x: 0, y: 0, width: size.width, height: size.height),
                   from: NSRect.zero,
                   operation: .copy,
                   fraction: 1.0)
        if let tintColor {
            tintColor.setFill()
        }
        let imageRect = NSRect(origin: .zero, size: image.size)
        imageRect.fill(using: .sourceIn)

        newImage.unlockFocus()
        newImage.size = size
        guard let data = newImage.tiffRepresentation else { return nil }

        self.init(data: data)
    }

    func resized(to size: NSSize) -> NSImage? {
        let newImage = NSImage(size: size, flipped: false, drawingHandler: { (rect) -> Bool in
            self.draw(in: rect,
                 from: NSRect.zero,
                 operation: .copy,
                 fraction: 1.0)
            return true
        })

        return newImage
    }
    
    func crop(rect: CGRect) -> NSImage {
        let result = NSImage(size: rect.size)
        result.lockFocus()

        let destRect = CGRect(origin: .zero, size: result.size)
        draw(in: destRect, from: rect, operation: .copy, fraction: 1.0)

        result.unlockFocus()
        return result
    }
    
    func rotated(by degrees: CGFloat) -> NSImage {
        let sinDegrees = abs(sin(degrees * CGFloat.pi / 180.0))
        let cosDegrees = abs(cos(degrees * CGFloat.pi / 180.0))
        let newSize = CGSize(width: size.height * sinDegrees + size.width * cosDegrees,
                             height: size.width * sinDegrees + size.height * cosDegrees)

        let imageBounds = NSRect(x: (newSize.width - size.width) / 2,
                                 y: (newSize.height - size.height) / 2,
                                 width: size.width, height: size.height)

        let otherTransform = NSAffineTransform()
        otherTransform.translateX(by: newSize.width / 2, yBy: newSize.height / 2)
        otherTransform.rotate(byDegrees: degrees)
        otherTransform.translateX(by: -newSize.width / 2, yBy: -newSize.height / 2)

        let rotatedImage = NSImage(size: newSize)
        rotatedImage.lockFocus()
        otherTransform.concat()
        draw(in: imageBounds, from: CGRect.zero, operation: NSCompositingOperation.copy, fraction: 1.0)
        rotatedImage.unlockFocus()

        return rotatedImage
    }
}
