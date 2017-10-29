//
//  HearthstoneTopDeck.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 11/10/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import Kanna
import RegexUtil

struct HearthstoneTopDeck: HttpImporter {
    var siteName: String {
        return "Hearthstonetopdeck"
    }

    var handleUrl: RegexPattern {
        return "hearthstonetopdeck\\.com\\/deck"
    }

    var preferHttps: Bool {
        return false
    }

    func loadDeck(doc: HTMLDocument, url: String) -> (Deck, [Card])? {
        guard let nameNode = doc.at_xpath("//h1[contains(@class, 'panel-title')]"),
            let deckName = nameNode.text?.replace("\\s+", with: " ").trim() else {
                logger.error("Deck name not found")
                return nil
        }
        logger.verbose("Got deck name \(deckName)")

        let xpath = "//div[contains(@class, 'deck_banner_description')]"
            + "//span[contains(@class, 'midlarge')]/span"
        let nodeInfos = doc.xpath(xpath)
        guard let className = nodeInfos[1].text?.trim(),
            let playerClass = CardClass(rawValue: className.lowercased()) else {
                logger.error("Class not found")
                return nil
        }
        logger.verbose("Got class \(playerClass)")

        let deck = Deck()
        deck.playerClass = playerClass
        deck.name = deckName

        var cards: [Card] = []
        let cardNodes = doc.xpath("//div[contains(@class, 'cardname')]/span")
        for cardNode in cardNodes {
            guard let nameStr = cardNode.text else { continue }
            let matches = nameStr.matches("^\\s*(\\d+)\\s+(.*)\\s*$")
            logger.verbose("\(nameStr) \(matches)")
            if let countStr = matches.first?.value,
                let count = Int(countStr),
                let cardName = matches.last?.value,
                let card = Cards.by(englishNameCaseInsensitive: cardName) {
                card.count = count
                logger.verbose("Got card \(card)")
                cards.append(card)
            }
        }
        logger.verbose("is valid : \(deck.isValid()) \(deck.countCards())")
        return (deck, cards)
    }
}
