//
//  Hearthpwn.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 25/02/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import Kanna
import CleanroomLogger

struct Hearthpwn: HttpImporter {

    var siteName: String {
        return "HearthPwn"
    }

    var handleUrl: String {
        return "hearthpwn\\.com\\/decks"
    }

    var preferHttps: Bool {
        return false
    }

    func loadDeck(doc: HTMLDocument, url: String) -> Deck? {
        guard let nameNode = doc.at_xpath("//h2[contains(@class, 'deck-title')]"),
            let deckName = nameNode.text else {
                Log.error?.message("Deck name not found")
                return nil
        }
        Log.verbose?.message("Got deck name \(deckName)")

        guard let classNode = doc.at_xpath("//section[contains(@class, 'deck-info')]"),
            let clazz = classNode["class"],
            let playerClass = CardClass(rawValue: clazz
                .replace("deck-info", with: "").trim().lowercaseString) else {
                    Log.error?.message("Class not found")
                    return nil
        }
        Log.verbose?.message("Got class \(playerClass)")

        let deck = Deck(playerClass: playerClass, name: deckName)

        for clazz in ["class-listing", "neutral-listing"] {
            let xpath = "//*[contains(@class, '\(clazz)')]//td[contains(@class, 'col-name')]//a"
            let cardNodes = doc.xpath(xpath)
            for cardNode in cardNodes {
                guard let cardName = cardNode.text?.trim() else { continue }
                var count: Int?
                if let dataCount = cardNode["data-count"] {
                    count = Int(dataCount)
                }

                if let count = count,
                    let card = Cards.by(englishName: cardName.trim()) {
                    card.count = count
                    Log.verbose?.message("Got card \(card)")
                    deck.addCard(card)
                }
            }
        }
        return deck
    }
}
