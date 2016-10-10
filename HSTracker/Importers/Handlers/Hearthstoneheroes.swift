//
//  Hearthstoneheroes.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 9/10/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import Kanna
import CleanroomLogger

struct HearthstoneHeroes: HttpImporter {

    var siteName: String {
        return "Hearthstoneheroes"
    }

    var handleUrl: String {
        return "hearthstoneheroes\\.de\\/decks"
    }

    var preferHttps: Bool {
        return false
    }

    func loadDeck(doc: HTMLDocument, url: String) -> Deck? {
        var xpath = "//header[@class='panel-heading']/h1[@class='panel-title']"
        guard let nameNode = doc.at_xpath(xpath),
            let deckName = nameNode.text else {
                Log.error?.message("Deck name not found")
                return nil
        }
        Log.verbose?.message("Got deck name \(deckName)")

        xpath = "//*[@class='breadcrumb']//span[contains(@class, 'hsIcon')]"
        guard let classNode = doc.at_xpath(xpath),
            let className = classNode["class"] else {
                Log.error?.message("Class not found")
                return nil
        }
        let clazz = className.uppercaseString.replace("HSICON ", with: "")
        guard let playerClass = CardClass(rawValue: clazz) else {
            Log.error?.message("Class not found")
            return nil
        }
        Log.verbose?.message("Got class \(playerClass)")

        let deck = Deck(playerClass: playerClass, name: deckName)

        xpath = "//*[@id='list']/div/table/tbody/tr"
        let cardNodes = doc.xpath(xpath)
        for cardNode in cardNodes {
            if let a = cardNode.at_xpath(".//a"),
                let englishName = a["data-lang-en"],
                let card = Cards.by(englishName: englishName),
                let span = cardNode.at_xpath(".//span[@class='text-muted']"),
                let text = span.text?.lowercaseString.replace("x", with: ""),
                let count = Int(text) {
                card.count = count
                Log.verbose?.message("Got card \(card)")
                deck.addCard(card)
            }
        }
        
        return deck
    }
}
