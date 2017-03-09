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

    private static var cache: [String: NSImage] = [:]
    static func clearCache() {
        cache = [:]
    }

    static func tile(for card: Card,
                     completion: @escaping ((NSImage?) -> Void)) {
        if let image = cache[card.id] {
            completion(image)
            return
        }

        if let hearthstone = (NSApp.delegate as? AppDelegate)?.hearthstone,
           let assetGenerator = hearthstone.assetGenerator,
            Settings.useHearthstoneAssets {
            assetGenerator.tile(card: card) { (image, error) in
                 if let _ = error {
                    loadTile(card: card, completion: completion)
                } else if let image = image {
                     cache[card.id] = image
                    completion(image)
                }
            }
        } else {
            loadTile(card: card, completion: completion)
        }
    }

    private static func loadTile(card: Card, completion: @escaping ((NSImage?) -> Void)) {
        // Check in resource bundle
        if let image = NSImage(contentsOfFile:
            "\(Bundle.main.resourcePath!)/Resources/Small/\(card.id).png") {
            cache[card.id] = image
            completion(image)
            return
        }

        // Check if the image has been downloaded
        let path = Paths.tiles.appendingPathComponent("\(card.id).png")
        if let image = NSImage(contentsOf: path) {
            cache[card.id] = image
            completion(image)
            return
        }

        // Download image
        let cardUrl = "https://art.hearthstonejson.com/v1/tiles/\(card.id).png"
        guard let url = URL(string: cardUrl) else {
            completion(nil)
            return
        }
        Log.verbose?.message("downloading \(url) to \(path)")

        DispatchQueue.global().async {
            URLSession.shared.dataTask(with: url) { data, _, error in
                if let error = error {
                    Log.error?.message("download error \(error)")
                    completion(nil)
                } else if let data = data,
                    let image = NSImage(data: data) {
                    try? data.write(to: path, options: [.atomic])

                    cache[card.id] = image
                    completion(image)
                }
                }.resume()
        }
    }
}
