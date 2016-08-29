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

final class Hearthhead: BaseNetImporter, NetImporterAware {
    static let classes = [
        1: "warrior",
        2: "paladin",
        3: "hunter",
        4: "rogue",
        5: "priest",
        7: "shaman",
        8: "mage",
        9: "warlock",
        11: "druid"
    ]

    var siteName: String {
        return "Hearthhead"
    }

    func handleUrl(url: String) -> Bool {
        return url.match("hearthhead\\.com\\/deck=")
    }

    func loadDeck(url: String, completion: Deck? -> Void) throws {
        loadHtml(url) { (html) -> Void in
            if let html = html, doc = Kanna.HTML(html: html, encoding: NSUTF8StringEncoding) {
                var className: String?
                if let classNode = doc.at_xpath("//div[@class='deckguide-hero']") {
                    if let clazz = classNode["data-class"], classId = Int(clazz) {
                        className = Hearthhead.classes[classId]
                        Log.verbose?.message("found \(className)")
                    }
                }
                var deckName: String?
                if let deckNode = doc.at_xpath("//h1[@id='deckguide-name']") {
                    deckName = deckNode.text?.trim()
                    Log.verbose?.message("found \(deckName)")
                }

                var cards = [String: Int]()
                for cardNode in doc.xpath("//div[contains(@class,'deckguide-cards-type')]/ul/li") {
                    var cardId: String?
                    if let cardNameNode = cardNode.at_xpath("a"),
                        cardName = cardNameNode.text,
                        card = Cards.byEnglishName(cardName) {
                            cardId = card.id
                            Log.verbose?.message("\(cardName)")
                    }
                    var count = 1
                    if let cardNodeHTML = cardNode.text {
                        if cardNodeHTML.match("x[0-9]+$") {
                            if let match = cardNodeHTML.matches("x([0-9]+)$").first {
                                let qty: String = match.value
                                if let _count = Int(qty) {
                                    count = _count
                                }
                            }
                        }
                    }

                    if let cardId = cardId {
                        cards[cardId] = count
                    }
                }

                if let className = className,
                    playerClass = CardClass(rawValue: className.uppercaseString)
                    where self.isCount(cards) {
                    self.saveDeck(deckName, playerClass: playerClass,
                                  cards: cards, isArena: false, completion: completion)
                    return
                }
            }
            completion(nil)
        }
    }
}
