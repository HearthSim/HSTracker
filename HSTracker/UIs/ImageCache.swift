/*
 * This file is part of the HSTracker package.
 * (c) Benjamin Michotte <bmichotte@gmail.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 *
 * Created on 16/02/16.
 */

import Foundation

enum FromDestination: Int {
    case Bundle,
        Assets,
        Path
};

struct ImageCache {

    static func cardImage(card: Card) -> NSImage? {
        if let appSupport = NSSearchPathForDirectoriesInDomains(.ApplicationSupportDirectory, .UserDomainMask, true).first {
            let path = "\(appSupport)/HSTracker/cards/\(card.cardId).png"
            let image = imageNamed(path, from: .Path)

            return cropped(image)
        }
        return nil
    }

    private static func cropped(image: NSImage?) -> NSImage? {
        if let image = image {
            let target = NSImage(size: NSMakeSize(177, 259))
            target.lockFocus()
            image.drawAtPoint(NSMakePoint(0, 0),
                fromRect: NSMakeRect(7, 14, 177, 259),
                operation: .CompositeSourceOver, fraction: 1.0)
            target.unlockFocus()

            return target
        }
        return nil
    }

    static func smallCardImage(card: Card) -> NSImage? {
        return imageNamed("\(card.cardId).png", from: .Bundle)
    }

    static func gemImage(rarity: Rarity?) -> NSImage? {
        return image("gem", rarity)
    }

    static func frameImage(rarity: Rarity?) -> NSImage? {
        return image("frame", rarity)
    }
    
    private static func image(base:String, _ rarity: Rarity?) -> NSImage? {
        var image: String = "\(base)"
        if let rarity = rarity {
            switch rarity {
            case .Common: image += "_common"
            case .Rare: image += "_rare"
            case .Epic: image += "_epic"
            case .Legendary: image += "_legendary"
            case .Golden: image += "_golden"
            default: break
            }
        }
        return imageNamed(image, from: .Assets)
    }

    static func darkenImage() -> NSImage? {
        return imageNamed("dark", from: .Assets)
    }
    
    static func fadeImage() -> NSImage? {
        return imageNamed("fade", from: .Assets)
    }

    static func frameLegendary() -> NSImage? {
        return imageNamed("icon_legendary", from: .Assets)
    }

    static func frameCountbox(rarity: Rarity?) -> NSImage? {
        return image("countbox", rarity)
    }

    static func classImage(playerClass: String) -> NSImage? {
        return imageNamed(playerClass.lowercaseString, from: .Assets)
    }

    static func asset(asset: String) -> NSImage? {
        return imageNamed(asset, from: .Assets)
    }

    static func imageNamed(path: String, from: FromDestination) -> NSImage? {
        switch from {
        case .Bundle:
            let fullPath = NSBundle.mainBundle().resourcePath! + "/Resources/Small/\(path)"
            // DDLogVerbose("Opening image \(fullPath)")
            return NSImage(contentsOfFile: fullPath)

        case .Assets:
            // DDLogVerbose("Opening image \(path)")
            return NSImage(named: path)

        case .Path:
            // DDLogVerbose("Opening image \(path)")
            return NSImage(contentsOfFile: path)
        }
    }
}
