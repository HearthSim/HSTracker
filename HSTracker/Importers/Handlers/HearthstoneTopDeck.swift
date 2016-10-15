//
//  HearthstoneTopDeck.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 11/10/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import Kanna
import CleanroomLogger

struct HearthstoneTopDeck: HttpImporter {
    var siteName: String {
        return "Hearthstonetopdeck"
    }

    var handleUrl: String {
        return "hearthstonetopdeck\\.com\\/deck"
    }

    var preferHttps: Bool {
        return false
    }

    func loadDeck(doc: HTMLDocument, url: String) -> Deck? {
        guard let nameNode = doc.at_xpath("//h1[contains(@class, 'panel-title')]"),
            let deckName = nameNode.text?.replace("\\s+", with: " ") else {
                Log.error?.message("Deck name not found")
                return nil
        }
        Log.verbose?.message("Got deck name \(deckName)")

        let xpath = "//div[contains(@class, 'deck_banner_description')]"
            + "//span[contains(@class, 'midlarge')]/span"
        let nodeInfos = doc.xpath(xpath)
        guard let className = nodeInfos[1].text?.trim(),
            let playerClass = CardClass(rawValue: className.lowercaseString) else {
                Log.error?.message("Class not found")
                return nil
        }
        Log.verbose?.message("Got class \(playerClass)")

        let deck = Deck(playerClass: playerClass, name: deckName)

        let cardNodes = doc.xpath("//div[contains(@class, 'cardname')]/span")
        for cardNode in cardNodes {
            guard let nameStr = cardNode.text else { continue }
            let matches = nameStr.matches("^\\s*(\\d+)\\s+(.*)\\s*$")
            Log.verbose?.message("\(nameStr) \(matches)")
            if let countStr = matches.first?.value,
                let count = Int(countStr),
                let cardName = matches.last?.value,
                let card = Cards.by(englishNameCaseInsensitive: cardName) {
                card.count = count
                Log.verbose?.message("Got card \(card)")
                deck.addCard(card)
            }
        }
        Log.verbose?.message("is valid : \(deck.isValid()) \(deck.countCards())")
        return deck
    }
}
