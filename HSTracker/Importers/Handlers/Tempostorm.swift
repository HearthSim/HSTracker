//
//  Tempostorm.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 9/10/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import CleanroomLogger

class Tempostorm: BaseNetImporter, NetImporterAware {

    var siteName: String {
        return "TempoStorm"
    }

    func handleUrl(url: String) -> Bool {
        return url.match("tempostorm\\.com\\/hearthstone\\/decks")
    }

    func loadDeck(url: String, completion: Deck? -> Void) throws {

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

        loadJson(url, parameters: parameters) { (json) in
            guard let json = json as? [String: AnyObject] else {
                completion(nil)
                return
            }
            print("\(json)")
            guard let className = json["playerClass"] as? String,
                let playerClass = CardClass(rawValue: className.uppercaseString) else {
                    Log.error?.message("Can't find class name")
                    completion(nil)
                    return
            }
            Log.verbose?.message("got class: \(playerClass)")
            guard let name = json["name"] as? String else {
                Log.error?.message("Can't find deck name")
                completion(nil)
                return
            }
            Log.verbose?.message("got deck name \(name)")
            var cards = [String: Int]()
            guard let jsonCards = json["cards"] as? [[String: AnyObject]] else {
                Log.error?.message("Can't cards")
                completion(nil)
                return
            }
            for jsonCard: [String: AnyObject] in jsonCards {
                if let cardData = jsonCard["card"] as? [String: AnyObject],
                    let name = cardData["name"] as? String,
                    let card = Cards.by(englishNameCaseInsensitive: name) {

                    if let quantity = jsonCard["cardQuantity"] as? Int {

                    cards[card.id] = quantity
                    }
                }
            }

            let gameModeType = json["gameModeType"] as? String ?? "constructed"

            if self.isCount(cards) {
                self.saveDeck(name, playerClass: playerClass,
                              cards: cards, isArena: gameModeType == "arena",
                              completion: completion)
                return
            }

            completion(nil)
        }
    }

}
