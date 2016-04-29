//
//  NetImporter.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 25/02/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation

enum NetImporterError: ErrorType {
    case InvalidUrl,
    UrlNotSupported
}

protocol NetImporterAware {
    func handleUrl(url: String) -> Bool
    func loadDeck(url: String, _ completion: Deck? -> Void) throws -> Void
    var siteName: String { get }
}

final class NetImporter {
    static var importers: [NetImporterAware] {
        return [
            Hearthpwn(), HearthpwnDeckBuilder(), Hearthnews(), Hearthhead(), Heartharena(),
            Hearthstats(), HearthstoneDecks()
        ]
    }

    static func netImport(url: String, _ completion: Deck? -> Void) throws {
        let realUrl = NSURL(string: url)
        guard let _ = realUrl else {
            throw NetImporterError.InvalidUrl
        }

        for importer in importers {
            if importer.handleUrl(url.lowercaseString) {
                try importer.loadDeck(url, completion)
                return
            }
        }

        throw NetImporterError.UrlNotSupported
    }
}
