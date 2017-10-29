//
//  HearthstoneDecks.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 25/02/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import Kanna
import RegexUtil

struct HearthstoneDecks: HttpImporter {

    static let classes = [
        "Chaman": "shaman",
        "Chasseur": "hunter",
        "Démoniste": "warlock",
        "Druide": "druid",
        "Guerrier": "warrior",
        "Mage": "mage",
        "Paladin": "paladin",
        "Prêtre": "priest",
        "Voleur": "rogue"
    ]

    var siteName: String {
        return "Hearthstone-Decks"
    }

    var handleUrl: RegexPattern {
        return "hearthstone-decks\\.com"
    }

    var preferHttps: Bool {
        return false
    }

    func loadDeck(doc: HTMLDocument, url: String) -> (Deck, [Card])? {
        guard let classNode = doc.at_xpath("//input[@id='classe_nom']"),
            let clazz = classNode["value"],
            let className = HearthstoneDecks.classes[clazz],
            let playerClass = CardClass(rawValue: className.lowercased()) else {
                logger.error("Class not found")
                return nil
        }
        logger.verbose("Got class \(playerClass)")

        guard let deckNode = doc.at_xpath("//div[@id='content']//h1"),
            let deckName = deckNode.text else {
                logger.error("Deck name not found")
                return nil
        }
        logger.verbose("Got deck name \(deckName)")

        let deck = Deck()
        deck.playerClass = playerClass
        deck.name = deckName

        var cards: [Card] = []
        for cardNode in doc.xpath("//table[contains(@class,'tabcartes')]//tbody//tr//a") {
            if let qty = cardNode["nb_card"],
                let cardId = cardNode["real_id"],
                let count = Int(qty),
                let card = Cards.by(cardId: cardId) {
                card.count = count
                logger.verbose("Got card \(card)")
                cards.append(card)
            }
        }
        
        return (deck, cards)
    }
}
