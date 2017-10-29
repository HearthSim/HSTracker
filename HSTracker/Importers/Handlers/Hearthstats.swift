//
//  Hearthstats.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 25/02/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import Kanna
import RegexUtil

struct Hearthstats: HttpImporter {

    var siteName: String {
        return "HearthStats"
    }

    var handleUrl: RegexPattern {
        return "hearthstats\\.net|hss\\.io"
    }

    var preferHttps: Bool {
        return true
    }

    func loadDeck(doc: HTMLDocument, url: String) -> (Deck, [Card])? {
        guard let node = doc.at_xpath("//div[contains(@class,'win-count')]//img"),
            let alt = node["alt"],
            let playerClass = CardClass(rawValue: alt.lowercased()) else {
                logger.error("Class not found")
                return nil
        }
        logger.verbose("Got class \(playerClass)")

        guard let deckNameNode = doc.at_xpath("//h1[contains(@class,'page-title')]"),
            let deckName = deckNameNode.innerHTML?.components(separatedBy: "<").first else {
                logger.error("Deck name not found")
                return nil
        }
        logger.verbose("Got deck name \(deckName)")

        let deck = Deck()
        deck.playerClass = playerClass
        deck.name = deckName

        var cards: [Card] = []
        for node in doc.xpath("//div[contains(@class,'cardWrapper')]") {
            if let cardName = node.at_xpath("div[@class='name']")?.text,
                let countValue = node.at_xpath("div[@class='qty']")?.text,
                let card = Cards.by(englishName: cardName),
                let count = Int(countValue) {
                card.count = count
                logger.verbose("Got card \(card)")
                cards.append(card)
            }
        }
        return (deck, cards)
    }
}
