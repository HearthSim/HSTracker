//
//  MinimalBar.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 31/05/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import GPUImage

class MinimalBar: CardBar {
    override var themeDir: String {
        return "minimal"
    }

    override func initVars() {
        createdIconOffset = -15
    }

    override func addCardImage() {
        var cardId: String?

        if let card = card {
            cardId = card.id
        } else if let playerClassID = playerClassID {
            cardId = playerClassID
        }

        if let cardId = cardId {
            let fullPath = NSBundle.mainBundle().resourcePath! + "/Resources/Small/\(cardId).png"
            if let image = NSImage(contentsOfFile: fullPath) {
                let gaussian = GaussianBlur()
                gaussian.blurRadiusInPixels = 1.5
                let filteredImage = image.filterWithOperation(gaussian)
                filteredImage.drawInRect(ratio(frameRect))
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
