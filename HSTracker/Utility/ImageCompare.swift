//
//  ImageCompare.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 11/06/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import CleanroomLogger

extension NSImage {
    var CGImage: CGImageRef? {
        if let imageData = self.TIFFRepresentation,
            data = CGImageSourceCreateWithData(imageData, nil) {
            return CGImageSourceCreateImageAtIndex(data, 0, nil)
        }
        return nil
    }
}

class ImageCompare {
    
    var original: NSImage?
    
    init(original: NSImage) {
        self.original = original
    }
    
    func rank() -> Int {
        var ranks: [Int: Int] = [:]
        for i in 1 ... 25 {
            if let fullImage = NSImage(named: "\(i).bmp"),
                image = ImageUtilities.resize(fullImage, size: NSSize(width: 24, height: 24)) {
                ranks[i] = compare(image)
            }
        }
        Log.verbose?.message("detected ranks : \(ranks)")
        return Array(ranks).sort { $0.1 < $1.1 }.last?.0 ?? -1
    }
    
    private func compare(with: NSImage,
                         threshold: CGFloat = 0.4, percent: CGFloat = 20) -> Int {
        guard let original = self.original else { return 0 }
        guard let origImage = original.CGImage else { return 0 }
        guard let withImage = with.CGImage else { return 0 }
        
        var score = 0
        let numPixels = original.size.width * original.size.height
        let testablePixels = Int(floor(numPixels / 100.0 * percent))

        guard let origProvider = CGImageGetDataProvider(origImage) else { return 0 }
        let origPixelData = CGDataProviderCopyData(origProvider)
        let origData: UnsafePointer<UInt8> = CFDataGetBytePtr(origPixelData)

        guard let pixelProvider = CGImageGetDataProvider(withImage) else { return 0 }
        let withPixelData = CGDataProviderCopyData(pixelProvider)
        let withData: UnsafePointer<UInt8> = CFDataGetBytePtr(withPixelData)
        
        for _ in 0 ..< testablePixels {
            let pixelX = Int(arc4random() % UInt32(original.size.width))
            let pixelY = Int(arc4random() % UInt32(original.size.height))
            
            let origPixelInfo: Int = ((Int(CGImageGetWidth(origImage)) * pixelY) + pixelX) * 4
            
            let origRed = CGFloat(origData[origPixelInfo])
            let origGreen = CGFloat(origData[origPixelInfo + 1])
            let origBlue = CGFloat(origData[origPixelInfo + 2])
            
            let withPixelInfo: Int = ((Int(CGImageGetWidth(withImage)) * pixelY) + pixelX) * 4
            
            let withRed = CGFloat(withData[withPixelInfo])
            let withGreen = CGFloat(withData[withPixelInfo + 1])
            let withBlue = CGFloat(withData[withPixelInfo + 2])
            
            let distance = CGFloat(sqrtf(powf(Float(origRed - withRed), 2)
                + powf(Float(origGreen - withGreen), 2)
                + powf(Float(origBlue - withBlue), 2)) / 255.0)
            
            if distance < threshold {
                score += 1
            }
        }
        
        return Int(Float(score) / Float(testablePixels) * 100.0)
    }
}
