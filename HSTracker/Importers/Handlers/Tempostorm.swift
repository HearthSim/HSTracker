//
//  Tempostorm.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 9/10/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import CleanroomLogger

struct Tempostorm: JsonImporter {

    var siteName: String {
        return "TempoStorm"
    }

    var handleUrl: String {
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

        Log.info?.message("Fetching \(url)")

        let http = Http(url: url)
        http.json(method: .get, parameters: parameters) { json in
            completion(json)
        }
    }

    func loadDeck(json: Any, url: String) -> (Deck, [Card])? {
        guard let json = json as? [String: Any] else {
            Log.error?.message("invalid json")
            return nil
        }
        guard let className = json["playerClass"] as? String,
            let playerClass = CardClass(rawValue: className.lowercased()) else {
                Log.error?.message("Class not found")
                return nil
        }
        Log.verbose?.message("Got class \(playerClass)")

        guard let deckName = json["name"] as? String else {
            Log.error?.message("Deck name not found")
            return nil
        }
        Log.verbose?.message("Got deck name \(deckName)")

        let deck = Deck()
        deck.playerClass = playerClass
        deck.name = deckName
        let gameModeType = json["gameModeType"] as? String ?? "constructed"
        deck.isArena = gameModeType == "arena"

        guard let jsonCards = json["cards"] as? [[String: AnyObject]] else {
            Log.error?.message("Card list not found")
            return nil
        }
        var cards: [Card] = []
        for jsonCard: [String: AnyObject] in jsonCards {
            if let cardData = jsonCard["card"] as? [String: AnyObject],
                let name = cardData["name"] as? String,
                let card = Cards.by(englishNameCaseInsensitive: name),
                let count = jsonCard["cardQuantity"] as? Int {
                card.count = count
                Log.verbose?.message("Got card \(card)")
                cards.append(card)
            }
        }
        return (deck, cards)
    }
}
