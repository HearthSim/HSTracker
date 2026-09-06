//
//  ImageUtilities.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 11/06/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation

// These helpers run from image download completions and from watcher threads.
// `lockFocus()` mutates the calling thread's shared `NSGraphicsContext` stack
// and is deprecated as of macOS 15, so they compose through
// `NSImage(size:flipped:drawingHandler:)`, which is safe from any thread.
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
        return NSImage(size: rect.size, flipped: false, drawingHandler: { _ -> Bool in
            NSGraphicsContext.current?.imageInterpolation = .high
            image.draw(at: NSPoint.zero,
                       from: rect,
                       operation: .copy,
                       fraction: 1.0)
            return true
        })
    }
    
    static func resize(image origImage: NSImage, size newSize: NSSize) -> NSImage? {
        if newSize == NSSize.zero {
            return nil
        }
        return NSImage(size: newSize, flipped: false, drawingHandler: { (rect) -> Bool in
            NSGraphicsContext.current?.imageInterpolation = .high
            origImage.draw(in: rect,
                           from: NSRect.zero,
                           operation: .copy,
                           fraction: 1.0)
            return true
        })
    }
}
