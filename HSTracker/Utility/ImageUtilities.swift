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
            Log.verbose?.message("\(image)")
            if let scaled = resize(image, size: NSSize(width: SizeHelper.BaseWidth,
                height: SizeHelper.BaseHeight)) {
            Log.verbose?.message("resize : \(scaled)")
            let cropped = cropRect(scaled, rect: NSRect(x: 31, y: 112, width: 24, height: 24))
            Log.verbose?.message("cropped : \(cropped)")
            return cropped
            }
        }
        Log.verbose?.message("! image")
        return nil
    }
    
    static func screenshotPlayerRankArea() -> NSImage? {
        let hearthstoneWindow = SizeHelper.hearthstoneWindow
        if let image = hearthstoneWindow.screenshot() {
            Log.verbose?.message("\(image)")
            let cropped = cropRect(image, rect: NSRect(x: 0, y: 0, width: image.size.width/5, height: image.size.height/3))
            Log.verbose?.message("cropped : \(cropped)")
            return cropped
            
        }
        Log.verbose?.message("! image")
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
    
    static func resizeImage(image: NSImage) -> NSImage {
        let height = SizeHelper.BaseHeight
        
        if image.size.height == height {
            return image
        }
        let ratio = 4.0 / 3.0
        let width = CGFloat(Double(height) * ratio)
        let cropWidth = CGFloat(Double(image.size.height) * ratio)
        let scaled = NSImage(size: NSSize(width: width, height: height))
        scaled.lockFocus()
        image.size = NSSize(width: cropWidth, height: image.size.height)
        NSGraphicsContext.currentContext()?.imageInterpolation = .High
        image.drawAtPoint(NSZeroPoint,
                                fromRect: NSRect(x: 0, y: 0, width: width, height: height),
                                operation: .CompositeCopy,
                                fraction:1.0)
        scaled.unlockFocus()
        return scaled
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