//
//  Hearthhead.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 25/02/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import CleanroomLogger
import Kanna

struct HearthHead: HttpImporter {
    static let classes: [Int: CardClass] = [
        1: .warrior,
        2: .paladin,
        3: .hunter,
        4: .rogue,
        5: .priest,
        7: .shaman,
        8: .mage,
        9: .warlock,
        11: .druid
    ]

    var siteName: String {
        return "Hearthhead"
    }

    var handleUrl: String {
        return "hearthhead\\.com\\/deck="
    }

    var preferHttps: Bool {
        return false
    }

    func loadDeck(doc: HTMLDocument, url: String) -> (Deck, [Card])? {
        guard let classNode = doc.at_xpath("//div[@class='deckguide-hero']"),
            let clazz = classNode["data-class"],
            let classId = Int(clazz),
            let playerClass = HearthHead.classes[classId] else {
                Log.error?.message("Class not found")
                return nil
        }
        Log.verbose?.message("Got class \(playerClass)")

        guard let deckNode = doc.at_xpath("//h1[@id='deckguide-name']"),
            let deckName = deckNode.text?.trim() else {
                Log.error?.message("Deck name not found")
                return nil
        }
        Log.verbose?.message("Got deck name \(deckName)")

        let deck = Deck()
        deck.playerClass = playerClass
        deck.name = deckName

        var cards: [Card] = []
        for cardNode in doc.xpath("//div[contains(@class,'deckguide-cards-type')]/ul/li") {
            if let cardNameNode = cardNode.at_xpath("a"),
                let cardName = cardNameNode.text,
                let card = Cards.by(englishName: cardName) {
                card.count = 1
                if let cardNodeHTML = cardNode.text {
                    if cardNodeHTML.match("x[0-9]+$") {
                        if let match = cardNodeHTML.matches("x([0-9]+)$").first,
                            let count = Int(match.value) {
                            card.count = count
                        }
                    }
                }

                Log.verbose?.message("Got card \(card)")
                cards.append(card)
            }
        }
        return (deck, cards)
    }
}
