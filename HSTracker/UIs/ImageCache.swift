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
}

struct ImageCache {

    static func cardImage(card: Card) -> NSImage? {
        if let appSupport = NSSearchPathForDirectoriesInDomains(
            .ApplicationSupportDirectory,
            .UserDomainMask, true).first {

            let path = "\(appSupport)/HSTracker/cards/\(card.id).png"
            let image = imageNamed(path, from: .Path)
            return image
        }
        return nil
    }

    static func smallCardImage(card: Card) -> NSImage? {
        return imageNamed("\(card.id).png", from: .Bundle)
    }

    static func gemImage(rarity: Rarity?) -> NSImage? {
        return image("gem", rarity: rarity)
    }

    static func frameImage(rarity: Rarity?) -> NSImage? {
        return image("frame", rarity: rarity)
    }

    private static func image(base: String, rarity: Rarity?) -> NSImage? {
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
        return image("countbox", rarity: rarity)
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
