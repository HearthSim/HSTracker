//
//  Paths.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 29/10/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation

/**
	Helper object for system folder locations
 */
class Paths {
    static let HSTracker: URL = {
        let paths = FileManager.default.urls(for: .applicationSupportDirectory,
                                             in: .userDomainMask)
        let applicationSupport = paths[0]
        return applicationSupport.appendingPathComponent("HSTracker", isDirectory: true)
    }()

    static let cards: URL = {
        return HSTracker.appendingPathComponent("cards", isDirectory: true)
    }()

    static let cardsBG: URL = {
        return HSTracker.appendingPathComponent("cardsBG", isDirectory: true)
    }()

    static let tiles: URL = {
        return HSTracker.appendingPathComponent("tiles", isDirectory: true)
    }()

    static let arts: URL = {
        return HSTracker.appendingPathComponent("arts", isDirectory: true)
    }()

    static let decks: URL = {
        return HSTracker.appendingPathComponent("decks", isDirectory: true)
    }()

    static let replays: URL = {
        return HSTracker.appendingPathComponent("replays", isDirectory: true)
    }()

    static let tmpReplays: URL = {
        return replays.appendingPathComponent("tmp", isDirectory: true)
    }()

    static let cardJson: URL = {
        return HSTracker.appendingPathComponent("json", isDirectory: true)
    }()

    static let arenaJson: URL = {
        return HSTracker.appendingPathComponent("arena", isDirectory: true)
    }()

    static let logs: URL = {
        let paths = FileManager.default.urls(for: .libraryDirectory,
                                             in: .userDomainMask)
        let libraryDirectory = paths[0]
        return libraryDirectory.appendingPathComponent("Logs/HSTracker", isDirectory: true)
    }()

	/**
		Creates folders at all path object location
	*/
    static func initDirs() {
        let paths = [cards, decks, replays, cardJson, logs, tmpReplays, tiles, arts, cards, cardsBG, arenaJson]
        let fileManager = FileManager.default
        for path in paths {
            if fileManager.fileExists(atPath: path.absoluteString) { continue }
            do {
                try FileManager.default
                    .createDirectory(at: path,
                                     withIntermediateDirectories: true,
                                     attributes: nil)
            } catch {
                logger.error("Can not create directory \(path) : \(error)")
            }
        }
    }
}
