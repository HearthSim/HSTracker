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

class HearthstoneHeroes: BaseNetImporter, NetImporterAware {

    var siteName: String {
        return "Hearthstoneheroes"
    }

    func handleUrl(url: String) -> Bool {
        return url.match("hearthstoneheroes\\.de\\/decks")
    }

    func loadDeck(url: String, completion: Deck? -> Void) throws {
        loadHtml(url) { (html) -> Void in
            guard let html = html,
                let doc = Kanna.HTML(html: html, encoding: NSUTF8StringEncoding) else {
                    completion(nil)
                    return
            }
            var xpath = "//header[@class='panel-heading']/h1[@class='panel-title']"
            guard let nameNode = doc.at_xpath(xpath), let deckName = nameNode.text else {
                completion(nil)
                return
            }
            Log.verbose?.message("got deck name \(deckName)")

            xpath = "//*[@class='breadcrumb']//span[contains(@class, 'hsIcon')]"
            guard let classNode = doc.at_xpath(xpath), let className = classNode["class"] else {
                completion(nil)
                return
            }
            let clazz = className.uppercaseString.replace("HSICON ", with: "")
            guard let playerClass = CardClass(rawValue: clazz) else {
                completion(nil)
                return
            }
            Log.verbose?.message("got class \(playerClass)")

            var cards = [String: Int]()

            xpath = "//*[@id='list']/div/table/tbody/tr"
            let cardNodes = doc.xpath(xpath)
            for cardNode in cardNodes {
                var englishName: String? = nil
                if let a = cardNode.at_xpath(".//a") {
                    englishName = a["data-lang-en"]
                }
                guard let name = englishName,
                    let card = Cards.by(englishName: name) else {
                    continue
                }
                Log.verbose?.message("\(card)")
                if let span = cardNode.at_xpath(".//span[@class='text-muted']"),
                    let text = span.text?.lowercaseString.replace("x", with: ""),
                    let count = Int(text) {
                    Log.verbose?.message("count \(count)")
                    cards[card.id] = count
                }
            }

            if self.isCount(cards) {
                self.saveDeck(deckName, playerClass: playerClass,
                              cards: cards, isArena: false,
                              completion: completion)
                return
            }

            completion(nil)
        }
    }
}
