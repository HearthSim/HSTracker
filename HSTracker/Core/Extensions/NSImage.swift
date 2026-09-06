//
//  NSImage.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 5/05/17.
//  Copyright © 2017 Benjamin Michotte. All rights reserved.
//

import Foundation

// `lockFocus()` / `unlockFocus()` push and pop the calling thread's
// `NSGraphicsContext` stack and are deprecated as of macOS 15. HSTracker calls
// these helpers from image download completions and from watcher threads, where
// that shared state is not safe to touch. `NSImage(size:flipped:drawingHandler:)`
// gives the handler its own context instead, so it is safe from any thread.
extension NSImage {
    convenience init?(named: String, size: NSSize, tintColor: NSColor? = nil) {
        guard let image = NSImage(named: named) else { return nil }

        self.init(size: size, flipped: false, drawingHandler: { _ -> Bool in
            image.draw(in: NSRect(x: 0, y: 0, width: size.width, height: size.height),
                       from: NSRect.zero,
                       operation: .copy,
                       fraction: 1.0)
            if let tintColor {
                tintColor.setFill()
            }
            let imageRect = NSRect(origin: .zero, size: image.size)
            imageRect.fill(using: .sourceIn)
            return true
        })
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
        return NSImage(size: rect.size, flipped: false, drawingHandler: { (destRect) -> Bool in
            self.draw(in: destRect, from: rect, operation: .copy, fraction: 1.0)
            return true
        })
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

        return NSImage(size: newSize, flipped: false, drawingHandler: { _ -> Bool in
            otherTransform.concat()
            self.draw(in: imageBounds, from: CGRect.zero, operation: NSCompositingOperation.copy, fraction: 1.0)
            return true
        })
    }
}
