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
    static let semaphore = DispatchSemaphore(value: 1)

    static func artUrl(cardId: String, lang: String) -> String {
        return "https://art.hearthstonejson.com/v1/render/latest/\(lang)/512x/\(cardId).png"
    }
    
    static func artUrl256(cardId: String) -> String {
        return "https://art.hearthstonejson.com/v1/256x/\(cardId).jpg"
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
    private static var cacheArt: [String: NSImage] = [:]
    static func clearCache() {
        ImageUtils.semaphore.wait()
        
        cache = [:]
        cacheArt = [:]
        
        ImageUtils.semaphore.signal()
    }

    static func tile(for cardId: String,
                     completion: @escaping ((NSImage?) -> Void)) {
        ImageUtils.semaphore.wait()
        let image = cache[cardId]
        ImageUtils.semaphore.signal()
        
        if let image = image {
            completion(image)
            return
        }
		
        loadTile(cardId: cardId, completion: completion)
    }
    
    static func art(for cardId: String, completion: @escaping ((NSImage?) -> Void)) {
        ImageUtils.semaphore.wait()
        let image = cacheArt[cardId]
        ImageUtils.semaphore.signal()
        
        if let image = image {
            completion(image)
            return
        }
        loadArt(cardId: cardId, completion: completion)
    }

    private static func loadTile(cardId: String, completion: @escaping ((NSImage?) -> Void)) {
        // Check in resource bundle
        if let image = NSImage(contentsOfFile:
            "\(Bundle.main.resourcePath!)/Resources/Small/\(cardId).png") {
            ImageUtils.semaphore.wait()
            cache[cardId] = image
            ImageUtils.semaphore.signal()
            
            completion(image)
            return
        }

        // Check if the image has been downloaded
        let path = Paths.tiles.appendingPathComponent("\(cardId).png")
        if let image = NSImage(contentsOf: path) {
            ImageUtils.semaphore.wait()
            cache[cardId] = image
            ImageUtils.semaphore.signal()
            
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

                    ImageUtils.semaphore.wait()
                    cache[cardId] = image
                    ImageUtils.semaphore.signal()
                    
                    completion(image)
                }
                }.resume()
        }
    }
    
    static func cachedArt(cardId: String) -> NSImage? {
        ImageUtils.semaphore.wait()
        let res = cacheArt[cardId]
        ImageUtils.semaphore.signal()
        
        return res
    }
    
    private static func loadArt(cardId: String, completion: @escaping ((NSImage?) -> Void)) {
        // Check if the image has been downloaded
        let path = Paths.arts.appendingPathComponent("\(cardId).jpg")
        if let image = NSImage(contentsOf: path) {
            ImageUtils.semaphore.wait()
            cacheArt[cardId] = image
            ImageUtils.semaphore.signal()
            
            completion(image)
            return
        }

        // Download image
        let cardUrl = artUrl256(cardId: cardId)
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
                    
                    ImageUtils.semaphore.wait()
                    cacheArt[cardId] = image
                    ImageUtils.semaphore.signal()
                    
                    completion(image)
                }
                }.resume()
        }
    }

}
