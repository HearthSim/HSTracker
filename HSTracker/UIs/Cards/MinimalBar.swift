//
//  MinimalBar.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 31/05/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import CoreImage
import AppKit

class MinimalBar: CardBar {
    override var themeDir: String {
        return "minimal"
    }

    override func initVars() {
        createdIconOffset = -15
    }

    private let filter = CIFilter(name: "CIGaussianBlur")

    override func addCardImage() {
        var cardId: String?

        if let card = card {
            cardId = card.id
        }

        if let cardId = cardId, let rp = Bundle.main.resourcePath {
            let fullPath = "\(rp)/Resources/Small/\(cardId).png"
            if let image = NSImage(contentsOfFile: fullPath) {
                if let imageData = image.tiffRepresentation,
                    let ciimage = CIImage(data: imageData),
                    let filter = filter {
                    filter.setDefaults()
                    filter.setValue(ciimage, forKey: kCIInputImageKey)
                    filter.setValue(1.5, forKey: kCIInputRadiusKey)
                    filter.outputImage?.draw(in: ratio(frameRect),
                                                   from: NSRect(origin: .zero,
                                                    size: image.size),
                                                   operation: .copy,
                                                   fraction: 1.0)
                } else {
                    image.draw(in: ratio(frameRect))
                }
            }
        }
    }

    override var flashColor: NSColor {
        return countTextColor
    }

    override var countTextColor: NSColor {
        guard let card = card else { return NSColor.white }

        switch card.rarity {
        case .rare:
            return NSColor(red: 0.1922, green: 0.5255, blue: 0.8706, alpha: 1.0)
        case .epic:
            return NSColor(red: 0.6784, green: 0.4431, blue: 0.9686, alpha: 1.0)
        case .legendary:
            return NSColor(red: 1.0, green: 0.6039, blue: 0.0627, alpha: 1.0)
        default:
            return NSColor.white
        }
    }

    override func addCountBox() {
    }
}
