//
//  Hearthnews.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 25/02/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import CleanroomLogger
import Kanna

struct HearthNews: HttpImporter {

    var siteName: String {
        return "HearthNews"
    }

    var handleUrl: String {
        return "hearthnews\\.fr"
    }

    var preferHttps: Bool {
        return true
    }

    func loadDeck(doc: HTMLDocument, url: String) -> (Deck, [Card])? {
        guard let classNode = doc.at_xpath("//div[@hero_class]"),
            let clazz = classNode["hero_class"],
            let playerClass = CardClass(rawValue: clazz.lowercased()) else {
                Log.error?.message("Class not found")
                return nil
        }
        Log.verbose?.message("Got class \(playerClass)")

        guard let deckNode = doc.at_xpath("//div[@class='block_deck_content_deck_name']"),
            let deckName = deckNode.text?.trim() else {
                Log.error?.message("Deck name not found")
                return nil
        }
        Log.verbose?.message("Got deck name \(deckName)")

        let deck = Deck()
        deck.playerClass = playerClass
        deck.name = deckName

        var cards: [Card] = []
        for cardNode in doc.xpath("//a[@class='real_id']") {
            if let qty = cardNode["nb_card"],
                let cardId = cardNode["real_id"],
                let card = Cards.by(cardId: cardId),
                let count = Int(qty) {
                card.count = count
                Log.verbose?.message("Got card \(card)")
                cards.append(card)
            }
        }
        
        return (deck, cards)
    }
}
