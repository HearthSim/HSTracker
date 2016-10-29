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

struct ImageUtils {

    static func image(for card: Card) -> NSImage? {
        let path = Paths.cards.appendingPathComponent("\(card.id).png")
        if let image = NSImage(contentsOf: path) {
            return image
        } else {
            Log.info?.message("Image at \(path) may be corrupted or missing")
            if FileManager.default.fileExists(atPath: path.path) {
                do {
                    try FileManager.default.removeItem(at: path)
                } catch {
                    Log.verbose?.message("Failed to remove corrupted image at \(path)")
                }
            }
            return NSImage(named: "MissingCard")
        }
    }
}
