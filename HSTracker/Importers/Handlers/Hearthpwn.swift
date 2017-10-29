//
//  Hearthpwn.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 25/02/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import Kanna
import RegexUtil

struct Hearthpwn: HttpImporter {

    var siteName: String {
        return "HearthPwn"
    }

    var handleUrl: RegexPattern {
        return "hearthpwn\\.com\\/decks"
    }

    var preferHttps: Bool {
        return false
    }

    func loadDeck(doc: HTMLDocument, url: String) -> (Deck, [Card])? {
        guard let nameNode = doc.at_xpath("//h2[contains(@class, 'deck-title')]"),
            let deckName = nameNode.text else {
                logger.error("Deck name not found")
                return nil
        }
        logger.verbose("Got deck name \(deckName)")

        guard let classNode = doc.at_xpath("//section[contains(@class, 'deck-info')]"),
            let clazz = classNode["class"],
            let playerClass = CardClass(rawValue: clazz
                .replace("deck-info", with: "").trim().lowercased()) else {
                    logger.error("Class not found")
                    return nil
        }
        logger.verbose("Got class \(playerClass)")

        let deck = Deck()
        deck.playerClass = playerClass
        deck.name = deckName

        var cards: [Card] = []
        let xpath = "//td[contains(@class,'col-name')]//a[contains(@href,'/cards/') "
            + "and contains(@class,'rarity')]"
        let cardNodes = doc.xpath(xpath)
        for cardNode in cardNodes {
            guard let cardName = cardNode.text?.trim() else { continue }
            var count: Int?
            if let dataCount = cardNode["data-count"] {
                count = Int(dataCount)
            }

            if let count = count,
                let card = Cards.by(englishName: cardName) {
                card.count = count
                logger.verbose("Got card \(card)")
                cards.append(card)
            }
        }
        return (deck, cards)
    }
}
