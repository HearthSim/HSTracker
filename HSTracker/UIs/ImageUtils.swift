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

    static func tile(for card: Card,
                     completion: @escaping ((NSImage?) -> Void)) -> NSImage? {
        return tile(for: card.id, completion: completion)
    }

    static func tile(for card: String,
                     completion: @escaping ((NSImage?) -> Void)) -> NSImage? {
        // Check in resource bundle
        if let image = NSImage(contentsOfFile:
            "\(Bundle.main.resourcePath!)/Resources/Small/\(card).png") {
            return image
        }

        // Check if the image has been downloaded
        let path = Paths.tiles.appendingPathComponent("\(card).png")
        if let image = NSImage(contentsOf: path) {
            return image
        }

        // Download image
        guard let url = URL(string: "https://art.hearthstonejson.com/v1/tiles/\(card).png")
            else { return nil }
        Log.verbose?.message("downloading \(url) to \(path)")

        DispatchQueue.global().async {
            URLSession.shared.dataTask(with: url) { data, _, error in
                if error != nil {
                    Log.error?.message("download error \(error)")
                } else if let data = data,
                    let image = NSImage(data: data) {
                    try? data.write(to: path, options: [.atomic])

                    DispatchQueue.main.async {
                        completion(image)
                    }
                    return
                }
                DispatchQueue.main.async {
                    completion(nil)
                }
                }.resume()
        }

        return nil
    }
}
