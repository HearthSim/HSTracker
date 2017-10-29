//
//  Tempostorm.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 9/10/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import RegexUtil

struct Tempostorm: JsonImporter {

    var siteName: String {
        return "TempoStorm"
    }

    var handleUrl: RegexPattern {
        return "tempostorm\\.com\\/hearthstone\\/decks"
    }

    var preferHttps: Bool {
        return true
    }

    func loadJson(url: String, completion: @escaping (Any?) -> Void) {
        guard let match = url.matches("/decks/([^/]+)$").first else {
            completion(nil)
            return
        }
        let slug = match.value
        let url = "https://tempostorm.com/api/decks/findOne"
        let parameters: [String: String] = [
            "filter": "{\"where\":{\"slug\":\"\(slug)\"},\"fields\":{},\"include\":"
                + "[{\"relation\":\"cards\",\"scope\":{\"include\":[\"card\"]}}]}"
        ]

        let http = Http(url: url)
        http.json(method: .get, parameters: parameters) { json in
            completion(json)
        }
    }

    func loadDeck(json: Any, url: String) -> (Deck, [Card])? {
        guard let json = json as? [String: Any] else {
            logger.error("invalid json")
            return nil
        }
        guard let className = json["playerClass"] as? String,
            let playerClass = CardClass(rawValue: className.lowercased()) else {
                logger.error("Class not found")
                return nil
        }
        logger.verbose("Got class \(playerClass)")

        guard let deckName = json["name"] as? String else {
            logger.error("Deck name not found")
            return nil
        }
        logger.verbose("Got deck name \(deckName)")

        let deck = Deck()
        deck.playerClass = playerClass
        deck.name = deckName
        let gameModeType = json["gameModeType"] as? String ?? "constructed"
        deck.isArena = gameModeType == "arena"

        guard let jsonCards = json["cards"] as? [[String: Any]] else {
            logger.error("Card list not found")
            return nil
        }
        var cards: [Card] = []
        for jsonCard: [String: Any] in jsonCards {
            if let cardData = jsonCard["card"] as? [String: Any],
                let name = cardData["name"] as? String,
                let card = Cards.by(englishNameCaseInsensitive: name),
                let count = jsonCard["cardQuantity"] as? Int {
                card.count = count
                logger.verbose("Got card \(card)")
                cards.append(card)
            }
        }
        return (deck, cards)
    }
}
