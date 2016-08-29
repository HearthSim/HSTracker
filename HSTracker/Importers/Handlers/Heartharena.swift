//
//  Heartharena.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 25/02/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import Kanna
import CleanroomLogger

final class Heartharena: BaseNetImporter, NetImporterAware {

    var siteName: String {
        return "HearthArena"
    }

    func handleUrl(url: String) -> Bool {
        return url.match("heartharena\\.com")
    }

    func loadDeck(url: String, completion: Deck? -> Void) throws {
        loadHtml(url) { (html) -> Void in
            if let html = html, doc = Kanna.HTML(html: html, encoding: NSUTF8StringEncoding) {
                var className: String?
                var deckName: String?
                if let classNode = doc.at_xpath("//h1[@class='class']") {
                    className = classNode.text?.lowercaseString
                    if let className = className {
                        deckName = String(format: NSLocalizedString("Arena %@ %@", comment: ""),
                                          className, NSDate().shortDateString())
                    }
                    Log.verbose?.message("found \(className) / name : \(deckName)")
                }

                var cards = [String: Int]()
                for cardNode in doc.xpath("//ul[@class='deckList']/li") {
                    if let qty = cardNode.at_xpath("span[@class='quantity']")?.text,
                        count = Int(qty),
                        cardName = cardNode.at_xpath("span[@class='name']")?.text,
                        card = Cards.byEnglishName(cardName) {
                            Log.verbose?.message("qty : \(count) name: \(card.id)")
                            cards[card.id] = count
                    }
                }

                if let className = className,
                    playerClass = CardClass(rawValue: className.uppercaseString)
                    where self.isCount(cards) {
                    self.saveDeck(deckName, playerClass: playerClass, cards: cards,
                                  isArena: true, completion: completion)
                    return
                }
            }
            completion(nil)
        }
    }
}
