//
//  ImageCompare.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 11/06/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation

extension NSImage {
    var CGImage: CGImage? {
        if let imageData = self.tiffRepresentation,
            let data = CGImageSourceCreateWithData(imageData as CFData, nil) {
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
    
    private func compare(with: NSImage,
                         threshold: CGFloat = 0.4, percent: CGFloat = 20) -> Int {
        guard let original = self.original else { return 0 }
        guard let origImage = original.CGImage else { return 0 }
        guard let withImage = with.CGImage else { return 0 }
        
        var score = 0
        let numPixels = original.size.width * original.size.height
        let testablePixels = Int(floor(numPixels / 100.0 * percent))

        guard let origProvider = origImage.dataProvider else { return 0 }
        let origPixelData = origProvider.data
        let origData: UnsafePointer<UInt8> = CFDataGetBytePtr(origPixelData)

        guard let pixelProvider = withImage.dataProvider else { return 0 }
        let withPixelData = pixelProvider.data
        let withData: UnsafePointer<UInt8> = CFDataGetBytePtr(withPixelData)
        
        for _ in 0 ..< testablePixels {
            let pixelX = Int(UInt32.random(in: 0...UInt32(original.size.width)))
            let pixelY = Int(UInt32.random(in: 0...UInt32(original.size.height)))
            
            let origPixelInfo: Int = ((Int(origImage.width) * pixelY) + pixelX) * 4
            
            let origRed = CGFloat(origData[origPixelInfo])
            let origGreen = CGFloat(origData[origPixelInfo + 1])
            let origBlue = CGFloat(origData[origPixelInfo + 2])
            
            let withPixelInfo: Int = ((Int(withImage.width) * pixelY) + pixelX) * 4
            
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
