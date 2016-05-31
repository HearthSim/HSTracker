//
//  MinimalBar.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 31/05/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation

class MinimalBar: CardBar {
    override var themeDir: String {
        return "minimal"
    }

    override func initVars() {
        createdIconOffset = -15
    }

    override func addCardImage() {
        guard let card = card else { return }

        let fullPath = NSBundle.mainBundle().resourcePath! + "/Resources/Small/\(card.id).png"
        if let image = NSImage(contentsOfFile: fullPath),
            data = image.TIFFRepresentation,
            ciImage = CIImage(data: data) {
            let filter = CIFilter(name: "CIGaussianBlur", withInputParameters: [
                kCIInputImageKey: ciImage,
                "inputRadius": 2
                ])
            if let output = filter?.valueForKey(kCIOutputImageKey) as? CIImage {
                output.drawInRect(ratio(frameRect),
                                  fromRect: ciImage.extent,
                                  operation: .CompositeSourceOver,
                                  fraction: 1.0)
            }
        }
    }

    override var flashColor: NSColor {
        return countTextColor
    }

    override var countTextColor: NSColor {
        guard let card = card else { return NSColor.whiteColor() }

        switch card.rarity {
        case .Rare:
            return NSColor(red: 0.1922, green: 0.5255, blue: 0.8706, alpha: 1.0)
        case .Epic:
            return NSColor(red: 0.6784, green: 0.4431, blue: 0.9686, alpha: 1.0)
        case .Legendary:
            return NSColor(red: 1.0, green: 0.6039, blue: 0.0627, alpha: 1.0)
        default:
            return NSColor.whiteColor()
        }
    }

    override func addCountBox() {
    }
}
