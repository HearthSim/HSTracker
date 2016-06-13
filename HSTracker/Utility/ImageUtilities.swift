//
//  ImageUtilities.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 11/06/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation

class ImageUtilities {
    class func screenshotPlayerRank() -> NSImage? {
        return SizeHelper.hearthstoneWindow.screenshot(x: 24, y: 730, width: 24, height: 24)
    }
    
    class func resize(origImage: NSImage, size: NSSize) -> NSImage? {
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