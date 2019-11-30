/*
 * This file is part of the HSTracker package.
 * (c) Benjamin Michotte <bmichotte@gmail.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 *
 * Created on 16/02/16.
 */

import AppKit
import Foundation
import HearthMirror

struct ImageUtils {

    static func artUrl(cardId: String, lang: String) -> String {
        return "https://art.hearthstonejson.com/v1/render/latest/\(lang)/512x/\(cardId).png"
    }

    static func image(for cardId: String) -> NSImage? {
        let path = Paths.cards.appendingPathComponent("\(cardId).png")
        if let image = NSImage(contentsOf: path) {
            return image
        } else {
            logger.info("Image at \(path) may be corrupted or missing")
            if FileManager.default.fileExists(atPath: path.path) {
                do {
                    try FileManager.default.removeItem(at: path)
                } catch {
                    logger.verbose("Failed to remove corrupted image at \(path)")
                }
            }
            return NSImage(named: NSImage.Name(rawValue: "MissingCard"))
        }
    }

    private static var cache: [String: NSImage] = [:]
    static func clearCache() {
        cache = [:]
    }

    static func tile(for cardId: String,
                     completion: @escaping ((NSImage?) -> Void)) {
        if let image = cache[cardId] {
            completion(image)
            return
        }
		
        /*if let assetGenerator = CoreManager.assetGenerator,
            Settings.useHearthstoneAssets {
            assetGenerator.tile(card: card) { (image, error) in
                 if error != nil {
                    loadTile(card: card, completion: completion)
                } else if let image = image {
                     cache[card.id] = image
                    completion(image)
                }
            }
        }*/
        loadTile(cardId: cardId, completion: completion)
    }

    private static func loadTile(cardId: String, completion: @escaping ((NSImage?) -> Void)) {
        // Check in resource bundle
        if let image = NSImage(contentsOfFile:
            "\(Bundle.main.resourcePath!)/Resources/Small/\(cardId).png") {
            cache[cardId] = image
            completion(image)
            return
        }

        // Check if the image has been downloaded
        let path = Paths.tiles.appendingPathComponent("\(cardId).png")
        if let image = NSImage(contentsOf: path) {
            cache[cardId] = image
            completion(image)
            return
        }

        // Download image
        let cardUrl = "https://art.hearthstonejson.com/v1/tiles/\(cardId).png"
        guard let url = URL(string: cardUrl) else {
            completion(nil)
            return
        }
        logger.verbose("downloading \(url) to \(path)")

        DispatchQueue.global().async {
            URLSession.shared.dataTask(with: url) { data, _, error in
                if let error = error {
                    logger.error("download error \(error)")
                    completion(nil)
                } else if let data = data,
                    let image = NSImage(data: data) {
                    try? data.write(to: path, options: [.atomic])

                    cache[cardId] = image
                    completion(image)
                }
                }.resume()
        }
    }
}
