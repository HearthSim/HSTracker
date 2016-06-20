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
import CleanroomLogger

enum FromDestination: Int {
    case Bundle,
        Assets,
        Path
}

struct ImageUtils {

    static func cardImage(card: Card) -> NSImage? {
        if let appSupport = NSSearchPathForDirectoriesInDomains(
            .ApplicationSupportDirectory,
            .UserDomainMask, true).first {

            let path = "\(appSupport)/HSTracker/cards/\(card.id).png"
            if let image = NSImage(contentsOfFile: path) {
                return image
            } else {
                Log.info?.message("Image at \(path) may be corrupted or missing")
                return NSImage(named: "MissingCard")
            }
        }
        return nil
    }

}
