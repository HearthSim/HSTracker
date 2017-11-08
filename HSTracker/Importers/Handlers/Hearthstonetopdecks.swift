//
//  Hearthstonetopdecks.swift
//  HSTracker
//
//  Created by Istvan Fehervari on 29/08/16.
//  Copyright © 2016 Istvan Fehervari. All rights reserved.
//

import Foundation
import Kanna
import RegexUtil

struct HearthstoneTopDecks: HttpImporter {

    var siteName: String {
        return "Hearthstonetopdecks"
    }

    var handleUrl: RegexPattern {
        return "hearthstonetopdecks\\.com\\/decks"
    }

    var preferHttps: Bool {
        return true
    }

    func loadDeck(doc: HTMLDocument, url: String) -> (Deck, [Card])? {
        guard let nameNode = doc.at_xpath("//h1[contains(@class, 'entry-title')]"),
            let deckName = nameNode.text else {
                logger.error("Deck name not found")
                return nil
        }
        logger.verbose("Got deck name \(deckName)")

        let xpath = "//div[contains(@class, 'deck-import-code')]/input[@type='text']"
        guard let deckStringNode = doc.at_xpath(xpath),
            let deckString = deckStringNode["value"]?.trim(),
            let (playerClass, cardList) = DeckSerializer.deserializeDeckString(deckString: deckString) else {
                logger.error("Card list not found")
                return nil
        }

        let deck = Deck()
        deck.name = deckName
        deck.playerClass = playerClass

        return (deck, cardList)
    }
}
