//
//  Hearthstonetopdecks.swift
//  HSTracker
//
//  Created by Istvan Fehervari on 29/08/16.
//  Copyright © 2016 Istvan Fehervari. All rights reserved.
//

import Foundation
import Kanna
import CleanroomLogger

struct HearthstoneTopDecks: HttpImporter {

    var siteName: String {
        return "Hearthstonetopdecks"
    }

    var handleUrl: String {
        return "hearthstonetopdecks\\.com\\/decks"
    }

    var preferHttps: Bool {
        return true
    }

    func loadDeck(doc: HTMLDocument, url: String) -> (Deck, [Card])? {
        guard let nameNode = doc.at_xpath("//h1[contains(@class, 'entry-title')]"),
            let deckName = nameNode.text else {
                Log.error?.message("Deck name not found")
                return nil
        }
        Log.verbose?.message("Got deck name \(deckName)")

        let xpath = "//div[contains(@class, 'deck-info')]/a[contains(@href, 'deck-class') ]"
        guard let classNode = doc.at_xpath(xpath),
            let className = classNode.text?.trim(),
            let playerClass = CardClass(rawValue: className.lowercased()) else {
                Log.error?.message("Class not found")
                return nil
        }
        Log.verbose?.message("Got class \(playerClass)")

        let deck = Deck()
        deck.playerClass = playerClass
        deck.name = deckName

        var cards: [Card] = []
        let cardNodes = doc.xpath("//*[contains(@class, 'deck-class')]/li")
        for cardNode in cardNodes {
            if let cardName = cardNode.at_xpath(".//a/span[@class='card-name']")?.text,
                let cardcountstr = cardNode.at_xpath("span[@class='card-count']")?.text,
                let count = Int(cardcountstr) {

                // Hearthstonetopdeck sport several cards with wrong capitalization
                // (e.g. N'Zoth)
                let fixedCardName = cardName.trim().replace("’", with: "'")
                if let card = Cards.by(englishNameCaseInsensitive: fixedCardName) {
                    card.count = count
                    Log.verbose?.message("Got card \(card)")
                    cards.append(card)
                }
            }
        }
        return (deck, cards)
    }
}
