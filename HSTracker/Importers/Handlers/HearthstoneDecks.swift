//
//  HearthstoneDecks.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 25/02/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import Kanna
import CleanroomLogger

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

    var handleUrl: String {
        return "hearthstone-decks\\.com"
    }

    var preferHttps: Bool {
        return false
    }

    func loadDeck(doc: HTMLDocument, url: String) -> Deck? {
        guard let classNode = doc.at_xpath("//input[@id='classe_nom']"),
            let clazz = classNode["value"],
            let className = HearthstoneDecks.classes[clazz],
            let playerClass = CardClass(rawValue: className.lowercased()) else {
                Log.error?.message("Class not found")
                return nil
        }
        Log.verbose?.message("Got class \(playerClass)")

        guard let deckNode = doc.at_xpath("//div[@id='content']//h1"),
            let deckName = deckNode.text else {
                Log.error?.message("Deck name not found")
                return nil
        }
        Log.verbose?.message("Got deck name \(deckName)")

        let deck = Deck(playerClass: playerClass, name: deckName)

        for cardNode in doc.xpath("//table[contains(@class,'tabcartes')]//tbody//tr//a") {
            if let qty = cardNode["nb_card"],
                let cardId = cardNode["real_id"],
                let count = Int(qty),
                let card = Cards.by(cardId: cardId) {
                card.count = count
                Log.verbose?.message("Got card \(card)")
                deck.add(card: card)
            }
        }
        
        return deck
    }
}
