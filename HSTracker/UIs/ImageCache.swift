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

class ImageCache {

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

    static func frameImageMask() -> NSImage? {
        return imageNamed("frame_mask.png", from: .Assets)
    }

    static func smallCardImage(card: Card) -> NSImage? {
        let image = card.englishName.lowercaseString
            .replace("[ ']", with: "-")
            .replace("[:.!]", with: "")
        return imageNamed("\(image).png", from: .Bundle)
    }

    static func gemImage(rarity: Rarity) -> NSImage? {
        var image: String
        switch rarity.rawValue {
        case "free": image = "gem_rarity_free"
        case "common": image = "gem_rarity_common"
        case "rare": image = "gem_rarity_rare"
        case "epic": image = "gem_rarity_epic"
        case "legendary": image = "gem_rarity_legendary"
        default: return nil
        }

        return imageNamed(image, from: .Assets)
    }

    static func frameDeckImage() -> NSImage? {
        return imageNamed("frame_deck", from: .Assets)
    }

    static func frameImage(rarity: Rarity?) -> NSImage? {
        var image: String = "frame"
        if let rarity = rarity {
            switch rarity.rawValue {
            case "common": image = "frame_rarity_common"
            case "rare": image = "frame_rarity_rare"
            case "epic": image = "frame_rarity_epic"
            case "legendary": image = "frame_rarity_legendary"
            case "golden": image = "frame_golden"
            default: break
            }
        }
        return imageNamed(image, from: .Assets)
    }

    static func darkenImage() -> NSImage? {
        return imageNamed("dark", from: .Assets)
    }

    static func frameLegendary() -> NSImage? {
        return imageNamed("frame_legendary", from: .Assets)
    }

    static func frameCount(number: Int) -> NSImage? {
        return imageNamed("frame_\(number)", from: .Assets)
    }

    static func frameCountbox() -> NSImage? {
        return imageNamed("frame_countbox", from: .Assets)
    }

    static func frameCountboxDeck() -> NSImage? {
        return imageNamed("frame_countbox_deck", from: .Assets)
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
