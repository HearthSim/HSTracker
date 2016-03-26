//
//  Heartharena.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 25/02/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import Kanna

final class Heartharena: BaseNetImporter, NetImporterAware {

    var siteName: String {
        return "HearthArena"
    }

    func handleUrl(url: String) -> Bool {
        return url.match("heartharena\\.com")
    }

    func loadDeck(url: String, _ completion: Deck? -> Void) throws {
        loadHtml(url) { (html) -> Void in
            if let html = html, doc = Kanna.HTML(html: html, encoding: NSUTF8StringEncoding) {
                var className: String?
                var deckName: String?
                if let classNode = doc.at_xpath("//h1[@class='class']") {
                    className = classNode.text?.lowercaseString
                    if let className = className {
                        deckName = String(format: NSLocalizedString("Arena %@ %@", comment: ""), className, NSDate().shortDateString())
                    }
                    DDLogVerbose("found \(className) / name : \(deckName)")
                }

                var cards = [String: Int]()
                for cardNode in doc.xpath("//ul[@class='deckList']/li") {
                    if let qty = cardNode.at_xpath("span[@class='quantity']")?.text,
                        let count = Int(qty),
                        let cardName = cardNode.at_xpath("span[@class='name']")?.text,
                        let card = Cards.byEnglishName(cardName) {
                            DDLogVerbose("qty : \(count) name: \(card.cardId)")
                            cards[card.cardId] = count
                    }
                }

                if self.isCount(cards) {
                    self.saveDeck(deckName, className!, cards, true, completion)
                    return
                }
            }
            completion(nil)
        }
    }
}