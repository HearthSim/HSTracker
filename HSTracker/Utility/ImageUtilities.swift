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
    static func screenshotFirstCard() -> NSImage? {
        let hearthstoneWindow = SizeHelper.hearthstoneWindow
        if let image = hearthstoneWindow.screenshot() {
            let cropped = cropRect(image: image,
                                   rect: SizeHelper.firstCardFrame())
            return cropped
        }
        return nil
    }

    static func screenshotOpponentRank() -> NSImage? {
        let hearthstoneWindow = SizeHelper.hearthstoneWindow
        if let image = hearthstoneWindow.screenshot() {
            let cropped = cropRect(image: image,
                                   rect: NSRect(x: 0,
                                    y: hearthstoneWindow.frame.height - (image.size.height / 5),
                                    width: image.size.width / 10,
                                    height: image.size.height / 5))
            return cropped
        }
        return nil
    }
    
    static func screenshotPlayerRank() -> NSImage? {
        let hearthstoneWindow = SizeHelper.hearthstoneWindow
        if let image = hearthstoneWindow.screenshot() {
            let cropped = cropRect(image: image,
                                   rect: NSRect(x: 0, y: 0,
                                    width: image.size.width / 10,
                                    height: image.size.height / 5))
            return cropped
        }
        return nil
    }

    static func cropRect(image: NSImage, rect: NSRect) -> NSImage {
        let target = NSImage(size: rect.size)
        target.lockFocus()
        NSGraphicsContext.current?.imageInterpolation = .high
        image.draw(at: NSPoint.zero,
                           from: rect,
                           operation: .copy,
                           fraction:1.0)
        target.unlockFocus()
        return target
    }
    
    static func resize(image origImage: NSImage, size: NSSize) -> NSImage? {
        let sourceImage = origImage
        let newSize = size
        let smallImage = NSImage(size: newSize)
        if smallImage.size == NSSize.zero {
            return nil
        }
        smallImage.lockFocus()
        sourceImage.size = newSize
        NSGraphicsContext.current!.imageInterpolation = .high
        sourceImage.draw(at: NSPoint.zero,
                                from: CGRect(x: 0, y: 0,
                                    width: newSize.width, height: newSize.height),
                                operation: .copy,
                                fraction:1.0)
        smallImage.unlockFocus()
        return smallImage
    }
}
