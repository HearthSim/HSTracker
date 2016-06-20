//
//  ImageUtilities.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 11/06/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import CleanroomLogger

struct ImageUtilities {
    static func screenshotPlayerRank() -> NSImage? {
        let hearthstoneWindow = SizeHelper.hearthstoneWindow
        if let image = hearthstoneWindow.screenshot() {
            let cropped = cropRect(image,
                                   rect: NSRect(x: 0, y: 0,
                                    width: image.size.width / 5,
                                    height: image.size.height / 3))
            return cropped
        }
        return nil
    }

    static func cropRect(image: NSImage, rect: NSRect) -> NSImage {
        let target = NSImage(size: rect.size)
        target.lockFocus()
        NSGraphicsContext.currentContext()?.imageInterpolation = .High
        image.drawAtPoint(NSZeroPoint,
                           fromRect: rect,
                           operation: .CompositeCopy,
                           fraction:1.0)
        target.unlockFocus()
        return target
    }
    
    static func resize(origImage: NSImage, size: NSSize) -> NSImage? {
        let sourceImage = origImage
        let newSize = size
        let smallImage = NSImage(size: newSize)
        if smallImage.size == NSSize.zero {
            return nil
        }
        smallImage.lockFocus()
        sourceImage.size = newSize
        NSGraphicsContext.currentContext()!.imageInterpolation = .High
        sourceImage.drawAtPoint(NSZeroPoint,
                                fromRect: CGRect(x: 0, y: 0,
                                    width: newSize.width, height: newSize.height),
                                operation: .CompositeCopy,
                                fraction:1.0)
        smallImage.unlockFocus()
        return smallImage
    }
}