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
    enum ImageType: Int {
        case tile, art, cardArt, cardArtBG
    }
    
    static let semaphore = DispatchSemaphore(value: 1)

    static func tileUrl(cardId: String) -> String {
        return "https://art.hearthstonejson.com/v1/tiles/\(cardId).png"
    }
    
    static func artUrl(cardId: String, lang: String) -> String {
        return "https://art.hearthstonejson.com/v1/render/latest/\(lang)/256x/\(cardId).png"
    }

    static func artUrlBG(cardId: String, lang: String) -> String {
        return "https://art.hearthstonejson.com/v1/bgs/latest/\(lang)/256x/\(cardId).png"
    }

    static func artUrl256(cardId: String) -> String {
        return "https://art.hearthstonejson.com/v1/256x/\(cardId).jpg"
    }

    private static var cache: [String: NSImage] = [:]
    private static var cacheArt: [String: NSImage] = [:]
    private static var cacheCardArt: [String: NSImage] = [:]
    private static var cacheCardArtBG: [String: NSImage] = [:]
    
    static func clearCache() {
        ImageUtils.semaphore.wait()
        
        cache = [:]
        cacheArt = [:]
        cacheCardArt = [:]
        cacheCardArtBG = [:]
        
        ImageUtils.semaphore.signal()
        
        clearDirectory(path: Paths.cards)
        clearDirectory(path: Paths.cardsBG)
        clearDirectory(path: Paths.arts)
        clearDirectory(path: Paths.tiles)
    }
    
    static func clearDirectory(path: URL) {
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(at: path,
                                                                       includingPropertiesForKeys: nil,
                                                                       options: .skipsHiddenFiles)
            for fileURL in fileURLs {
                try FileManager.default.removeItem(at: fileURL)
            }
        } catch {
            logger.error(error)
        }
    }

    static func cachedTile(cardId: String) -> NSImage? {
        ImageUtils.semaphore.wait()
        let res = cache[cardId]
        ImageUtils.semaphore.signal()
        
        return res
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
		
        loadImage(type: .tile, cardId: cardId, completion: completion)
    }
    
    static func art(for cardId: String, completion: @escaping ((NSImage?) -> Void)) {
        ImageUtils.semaphore.wait()
        let image = cacheArt[cardId]
        ImageUtils.semaphore.signal()
        
        if let image = image {
            completion(image)
            return
        }
        loadImage(type: .art, cardId: cardId, completion: completion)
    }
    
    static func cardArt(for cardId: String, completion: @escaping ((NSImage?) -> Void)) {
        ImageUtils.semaphore.wait()
        let image = cacheCardArt[cardId]
        ImageUtils.semaphore.signal()
        
        if let image = image {
            completion(image)
            return
        }
        loadImage(type: .cardArt, cardId: cardId, completion: completion)
    }
    
    static func cardArtBG(for cardId: String, completion: @escaping ((NSImage?) -> Void)) {
        ImageUtils.semaphore.wait()
        let image = cacheCardArtBG[cardId]
        ImageUtils.semaphore.signal()
        
        if let image = image {
            completion(image)
            return
        }
        loadImage(type: .cardArtBG, cardId: cardId, completion: completion)
    }

    static func cachedArt(cardId: String) -> NSImage? {
        ImageUtils.semaphore.wait()
        let res = cacheArt[cardId]
        ImageUtils.semaphore.signal()
        
        return res
    }
    
    private static func loadImage(type: ImageType, cardId: String, completion: @escaping ((NSImage?) -> Void)) {
        // Check if the image has been downloaded
        var path: URL
        switch type {
        case .tile:
            path = Paths.tiles.appendingPathComponent("\(cardId).jpg")
        case .art:
            path = Paths.arts.appendingPathComponent("\(cardId).jpg")
        case .cardArt:
            path = Paths.cards.appendingPathComponent("\(cardId).jpg")
        case .cardArtBG:
            path = Paths.cardsBG.appendingPathComponent("\(cardId).jpg")
        }
        if let image = NSImage(contentsOf: path) {
            ImageUtils.semaphore.wait()
            switch type {
            case .tile:
                cache[cardId] = image
            case .art:
                cacheArt[cardId] = image
            case .cardArt:
                cacheCardArt[cardId] = image
            case .cardArtBG:
                cacheCardArtBG[cardId] = image
            }
            ImageUtils.semaphore.signal()
            
            completion(image)
            return
        }

        // Download image
        let url: String
        switch type {
        case .tile:
            url = tileUrl(cardId: cardId)
        case .art:
            url = artUrl256(cardId: cardId)
        case .cardArt:
            url = artUrl(cardId: cardId, lang: Settings.hearthstoneLanguage?.rawValue ?? "enUS")
        case .cardArtBG:
            url = artUrlBG(cardId: cardId, lang: Settings.hearthstoneLanguage?.rawValue ?? "enUS")
        }
        guard let url = URL(string: url) else {
            completion(nil)
            return
        }
        logger.verbose("downloading \(type) \(url) to \(path)")

        DispatchQueue.global().async {
            URLSession.shared.dataTask(with: url) { data, _, error in
                if let error = error {
                    logger.error("download error \(error)")
                    completion(nil)
                } else if let data = data,
                    let image = NSImage(data: data) {
                    try? data.write(to: path, options: [.atomic])

                    ImageUtils.semaphore.wait()
                    switch type {
                    case .tile:
                        cache[cardId] = image
                    case .art:
                        cacheArt[cardId] = image
                    case .cardArt:
                        cacheCardArt[cardId] = image
                    case .cardArtBG:
                        cacheCardArtBG[cardId] = image
                    }
                    ImageUtils.semaphore.signal()
                    
                    completion(image)
                }
                }.resume()
        }
    }
}
