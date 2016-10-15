//
//  Hearthstats.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 25/02/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import Kanna
import CleanroomLogger

struct Hearthstats: HttpImporter {

    var siteName: String {
        return "HearthStats"
    }

    var handleUrl: String {
        return "hearthstats\\.net|hss\\.io"
    }

    var preferHttps: Bool {
        return true
    }

    func loadDeck(doc: HTMLDocument, url: String) -> Deck? {
        guard let node = doc.at_xpath("//div[contains(@class,'win-count')]//img"),
            let alt = node["alt"],
            let playerClass = CardClass(rawValue: alt.lowercaseString) else {
                Log.error?.message("Class not found")
                return nil
        }
        Log.verbose?.message("Got class \(playerClass)")

        guard let deckNameNode = doc.at_xpath("//h1[contains(@class,'page-title')]"),
            let deckName = deckNameNode.innerHTML?.componentsSeparatedByString("<").first else {
                Log.error?.message("Deck name not found")
                return nil
        }
        Log.verbose?.message("Got deck name \(deckName)")

        let deck = Deck(playerClass: playerClass, name: deckName)

        for node in doc.xpath("//div[contains(@class,'cardWrapper')]") {
            if let cardName = node.at_xpath("div[@class='name']")?.text,
                let countValue = node.at_xpath("div[@class='qty']")?.text,
                let card = Cards.by(englishName: cardName),
                let count = Int(countValue) {
                card.count = count
                Log.verbose?.message("Got card \(card)")
                deck.addCard(card)
            }
        }
        return deck
    }
}
