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

    static func frameImageMask() -> NSImage? {
        return self.imageNamed("frame_mask.png", from: .Assets)
    }

    static func smallCardImage(card: Card) -> NSImage? {
        let image = card.englishName.lowercaseString
        .replace(NSRegularExpression.rx("[ ']"), with: "-")
        .replace(NSRegularExpression.rx("[:.!]"), with: "")
        return self.imageNamed("\(image).png", from: .Bundle)
    }

    static func gemImage(rarity: String) -> NSImage? {
        var image: String
        switch rarity {
        case "free": image = "gem_rarity_free"
        case "common":image = "gem_rarity_common"
        case "rare":image = "gem_rarity_rare"
        case "epic":image = "gem_rarity_epic"
        case "legendary":image = "gem_rarity_legendary"
        default: return nil
        }

        return self.imageNamed(image, from: .Assets)
    }

    static func frameDeckImage() -> NSImage? {
        return self.imageNamed("frame_deck", from: .Assets)
    }

    static func frameImage(rarity: String?) -> NSImage? {
        var image: String = "frame"
        if let rarity = rarity {
            switch rarity {
            case "common":image = "frame_rarity_common"
            case "rare":image = "frame_rarity_rare"
            case "epic":image = "frame_rarity_epic"
            case "legendary":image = "frame_rarity_legendary"
            case "golden":image = "frame_golden"
            default: break
            }
        }
        return self.imageNamed(image, from: .Assets)
    }
    
    static func darkenImage() -> NSImage? {
        return self.imageNamed("darken", from: .Assets)
    }

    static func frameLegendary() -> NSImage? {
        return self.imageNamed("frame_legendary", from: .Assets)
    }

    static func frameCount(number: Int) -> NSImage? {
        return self.imageNamed("frame_\(number)", from: .Assets)
    }

    static func frameCountbox() -> NSImage? {
        return self.imageNamed("frame_countbox", from: .Assets)
    }

    static func frameCountboxDeck() -> NSImage? {
        return self.imageNamed("frame_countbox_deck", from: .Assets)
    }
    
    static func classImage(playerClass:String) -> NSImage? {
        return self.imageNamed(playerClass.lowercaseString, from: .Assets)
    }
    
    static func asset(asset:String) -> NSImage? {
        return self.imageNamed(asset, from: .Assets)
    }

    static func imageNamed(path: String, from: FromDestination) -> NSImage? {
        switch from {
        case .Bundle:
            let fullPath = NSBundle.mainBundle().resourcePath! + "/Resources/Small/\(path)"
            //DDLogVerbose("Opening image \(fullPath)")
            return NSImage(contentsOfFile: fullPath)

        case .Assets:
            //DDLogVerbose("Opening image \(path)")
            return NSImage(named: path)

        case .Path:
            //DDLogVerbose("Opening image \(path)")
            return NSImage(contentsOfFile: path)
        }
    }
}
