//
//  Heartharena.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 25/02/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import Kanna
import CleanroomLogger
import SwiftDate

struct HearthArena: HttpImporter {

    var siteName: String {
        return "HearthArena"
    }

    var handleUrl: String {
        return "heartharena\\.com"
    }

    var preferHttps: Bool {
        return false
    }

    func loadDeck(doc: HTMLDocument, url: String) -> (Deck, [Card])? {
        guard let classNode = doc.at_xpath("//h1[@class='class']"),
            let className = classNode.text?.components(separatedBy: " ").first,
            let playerClass = CardClass(rawValue: className.lowercased()) else {
                Log.error?.message("Class not found")
                return nil
        }
        Log.verbose?.message("Got class \(playerClass)")

        let deckName = String(format: NSLocalizedString("Arena %@ %@", comment: ""),
                              className, Date().iso8601(opts: [.withFullDate]))
        Log.verbose?.message("Got deck name \(deckName)")

        let deck = Deck()
        deck.playerClass = playerClass
        deck.name = deckName

        var cards: [Card] = []
        for cardNode in doc.xpath("//ul[@class='deckList']/li") {
            if let qty = cardNode.at_xpath("span[@class='quantity']")?.text,
                let count = Int(qty),
                let cardName = cardNode.at_xpath("span[@class='name']")?.text,
                let card = Cards.by(englishName: cardName) {
                card.count = count
                Log.verbose?.message("Got card \(card)")
                cards.append(card)
            }
        }
        return (deck, cards)
    }
}
