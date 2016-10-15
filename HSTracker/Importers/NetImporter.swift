//
//  NetImporter.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 25/02/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import Kanna
import CleanroomLogger

enum NetImporterError: ErrorType {
    case invalidUrl, urlNotSupported
}

protocol Importer {
    var siteName: String { get }
    var handleUrl: String { get }
    var preferHttps: Bool { get }
    func transformUrl(url: String) -> String
}
extension Importer {
    var preferHttps: Bool {
        return false
    }
    func transformUrl(url: String) -> String {
        var realUrl = url
        if preferHttps {
            realUrl = realUrl.replace("http://", with: "https://")
        }
        return realUrl
    }
}

protocol BaseFileImporter {
    func fileImport(url: NSURL) -> Deck?
}

protocol HttpImporter: Importer {
    func loadHtml(url: String, completion: HTMLDocument? -> Void)
    func loadDeck(doc: HTMLDocument, url: String) -> Deck?
}

extension HttpImporter {
    func loadHtml(url: String, completion: HTMLDocument? -> Void) {
        Log.info?.message("Fetching \(url)")

        let http = Http(url: url)
        http.html(.get) { doc in
            completion(doc)
        }
    }
}

protocol JsonImporter: Importer {
    func loadDeck(json: AnyObject, url: String) -> Deck?
    func loadJson(url: String, completion: AnyObject? -> Void)
}

extension JsonImporter {
    func loadJson(url: String, completion: AnyObject? -> Void) {
        Log.info?.message("Fetching \(url)")

        let http = Http(url: url)
        http.json(.get) { json in
            completion(json)
        }
    }
}

final class NetImporter {
    static var importers: [Importer] {
        return [
            Hearthpwn(), HearthpwnDeckBuilder(), HearthNews(), HearthHead(), HearthArena(),
            Hearthstats(), HearthstoneDecks(), HearthstoneTopDecks(), Tempostorm(),
            HearthstoneHeroes(), HearthstoneTopDeck(),

            // always keep this one at the last position
            MetaTagImporter()
        ]
    }

    static func netImport(url: String, completion: Deck? -> Void) throws {
        guard let _ = NSURL(string: url) else {
            throw NetImporterError.invalidUrl
        }

        for importer in importers {
            if url.lowercaseString.match(importer.handleUrl) {
                let realUrl = importer.transformUrl(url)

                if let httpImporter = importer as? HttpImporter {
                    httpImporter.loadHtml(realUrl, completion: { doc in
                        if let doc = doc,
                            let deck = httpImporter.loadDeck(doc, url: url)
                            where deck.isValid() {
                            Decks.instance.add(deck)
                            completion(deck)
                        } else {
                            completion(nil)
                        }
                    })

                } else if let jsonImporter = importer as? JsonImporter {
                    jsonImporter.loadJson(realUrl, completion: { json in
                        if let json = json,
                            let deck = jsonImporter.loadDeck(json, url: url)
                            where deck.isValid() {
                            Decks.instance.add(deck)
                            completion(deck)
                        } else {
                            completion(nil)
                        }
                    })
                }
                return
            }
        }
    }
}
