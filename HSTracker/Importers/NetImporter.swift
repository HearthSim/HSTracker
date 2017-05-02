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
import RealmSwift
import RegexUtil

enum NetImporterError: Error {
    case invalidUrl, urlNotSupported
}

protocol Importer {
    var siteName: String { get }
    var handleUrl: RegexPattern { get }
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
    func fileImport(url: URL) -> (Deck, [Card])?
}

protocol HttpImporter: Importer {
    func loadHtml(url: String, completion: @escaping (HTMLDocument?) -> Void)
    func loadDeck(doc: HTMLDocument, url: String) -> (Deck, [Card])?
}

extension HttpImporter {
    func loadHtml(url: String, completion: @escaping (HTMLDocument?) -> Void) {
        Log.info?.message("Fetching \(url)")

        let http = Http(url: url)
        http.html(method: .get) { doc in
            completion(doc)
        }
    }
}

protocol JsonImporter: Importer {
    func loadDeck(json: Any, url: String) -> (Deck, [Card])?
    func loadJson(url: String, completion: @escaping (Any?) -> Void)
}

extension JsonImporter {
    func loadJson(url: String, completion: @escaping (Any?) -> Void) {
        Log.info?.message("Fetching \(url)")

        let http = Http(url: url)
        http.json(method: .get) { json in
            completion(json)
        }
    }
}

final class NetImporter {
    static var importers: [Importer] {
        return [
            Hearthpwn(), HearthpwnDeckBuilder(), HearthArena(),
            Hearthstats(), HearthstoneDecks(), HearthstoneTopDecks(), Tempostorm(),
            HearthstoneHeroes(), HearthstoneTopDeck(),

            // always keep this one at the last position
            MetaTagImporter()
        ]
    }

    static func netImport(url: String, completion: @escaping (Deck?, String?) -> Void) throws {
        guard URL(string: url) != nil else {
            throw NetImporterError.invalidUrl
        }

        for importer in importers {
            if url.lowercased().match(importer.handleUrl) {
                let realUrl = importer.transformUrl(url: url)

                if let httpImporter = importer as? HttpImporter {
                    httpImporter.loadHtml(url: realUrl) { doc in
                        if let doc = doc,
                            let (deck, cards) = httpImporter.loadDeck(doc: doc, url: url),
                            cards.isValidDeck() {
							
							RealmHelper.add(deck: deck, with: cards)
                            completion(deck, checkDeckWithCollection(deck: deck))
                            
                        } else {
                            completion(nil, nil)
                        }
                    }
                    
                } else if let jsonImporter = importer as? JsonImporter {
                    jsonImporter.loadJson(url: realUrl) { json in
                        if let json = json,
                            let (deck, cards) = jsonImporter.loadDeck(json: json, url: url),
                            cards.isValidDeck() {
                            
                            RealmHelper.add(deck: deck, with: cards)
                            completion(deck, checkDeckWithCollection(deck: deck))
                            
                        } else {
                            completion(nil, nil)
                        }
                    }
                }
                return
            }
        }
    }

    static func checkDeckWithCollection(deck: Deck) -> String? {
        if deck.isArena { return nil }
        
        let cards = CollectionManager.default.collection()
        if cards.count == 0 {
            return NSLocalizedString("Can't get card collection", comment: "")
        }

        var missingCards: [Card] = []
        for deckCard in deck.sortedCards {
            guard let card = cards[deckCard.id] else {
                for _ in 1...deckCard.count {
                    missingCards.append(deckCard)
                }
                continue
            }

            let goldenCount = card[true] ?? 0
            let normalCount = card[false] ?? 0
            let cardCount = goldenCount + normalCount

            if cardCount < deckCard.count {
                for _ in 1...(deckCard.count - cardCount) {
                    missingCards.append(deckCard)
                }
            }
        }

        return CollectionManager.default.checkMissingCards(missingCards: missingCards)
    }
}
