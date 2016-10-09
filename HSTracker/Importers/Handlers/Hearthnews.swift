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

final class HearthNews: BaseNetImporter, NetImporterAware {

    var siteName: String {
        return "HearthNews"
    }

    func handleUrl(url: String) -> Bool {
        return url.match("hearthnews\\.fr")
    }

    func loadDeck(url: String, completion: Deck? -> Void) throws {
        loadHtml(url) { (html) -> Void in
            if let html = html, doc = Kanna.HTML(html: html, encoding: NSUTF8StringEncoding) {
                var className: String?
                if let classNode = doc.at_xpath("//div[@hero_class]") {
                    if let clazz = classNode["hero_class"] {
                        className = clazz.lowercaseString
                        Log.verbose?.message("found \(className)")
                    }
                }
                var deckName: String?
                if let deckNode = doc.at_xpath("//div[@class='block_deck_content_deck_name']") {
                    deckName = deckNode.text?.trim()
                    Log.verbose?.message("found \(deckName)")
                }

                var cards = [String: Int]()
                for cardNode in doc.xpath("//a[@class='real_id']") {
                    if let qty = cardNode["nb_card"],
                        cardId = cardNode["real_id"],
                        count = Int(qty) {
                            cards[cardId] = count
                    }
                }

                if let className = className,
                    playerClass = CardClass(rawValue: className.uppercaseString)
                    where self.isCount(cards) {
                    self.saveDeck(deckName, playerClass: playerClass, cards: cards,
                                  isArena: false, completion: completion)
                    return
                }
            }
            completion(nil)
        }
    }
}
