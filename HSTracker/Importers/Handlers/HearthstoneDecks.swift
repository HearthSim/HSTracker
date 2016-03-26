//
//  HearthstoneDecks.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 25/02/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import Kanna

final class HearthstoneDecks: BaseNetImporter, NetImporterAware {

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

    func handleUrl(url: String) -> Bool {
        return url.match("hearthstone-decks\\.com")
    }

    func loadDeck(url: String, _ completion: Deck? -> Void) throws {
        loadHtml(url) { (html) -> Void in
            if let html = html, doc = Kanna.HTML(html: html, encoding: NSUTF8StringEncoding) {
                var className: String?
                if let classNode = doc.at_xpath("//input[@id='classe_nom']") {
                    if let clazz = classNode["value"] {
                        className = HearthstoneDecks.classes[clazz]
                        DDLogVerbose("found \(className)")
                    }
                }
                var deckName: String?
                if let deckNode = doc.at_xpath("//div[@id='content']//h1") {
                    deckName = deckNode.text
                    DDLogVerbose("found \(deckName)")
                }

                var cards = [String: Int]()
                for cardNode in doc.xpath("//table[contains(@class,'tabcartes')]//tbody//tr//a") {
                    if let qty = cardNode["nb_card"], let cardId = cardNode["real_id"], count = Int(qty) {
                        cards[cardId] = count
                    }
                }

                if self.isCount(cards) {
                    self.saveDeck(deckName, className!, cards, false, completion)
                    return
                }
            }
            completion(nil)
        }
    }
}