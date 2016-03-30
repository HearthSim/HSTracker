//
//  Hearthpwn.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 25/02/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import Kanna
import CleanroomLogger

final class Hearthpwn: BaseNetImporter, NetImporterAware {

    var siteName: String {
        return "HearthPwn"
    }

    func handleUrl(url: String) -> Bool {
        return url.match("hearthpwn\\.com\\/decks")
    }

    func loadDeck(url: String, _ completion: Deck? -> Void) throws {
        loadHtml(url) { (html) -> Void in
            if let html = html, doc = Kanna.HTML(html: html, encoding: NSUTF8StringEncoding) {
                var deckName: String?
                if let nameNode = doc.at_xpath("//h2[contains(@class, 'deck-title')]") {
                    if let name = nameNode.text {
                        deckName = name
                    }
                }
                Log.verbose?.message("got deck name \(deckName)")

                var className: String?
                if let classNode = doc.at_xpath("//section[contains(@class, 'deck-info')]") {
                    if let clazz = classNode["class"] {
                        className = clazz.stringByReplacingOccurrencesOfString("deck-info", withString: "").trim()
                    }
                }
                guard let _ = className else {
                    // can't find class, ignore
                    Log.error?.message("class not found")
                    completion(nil)
                    return
                }
                Log.verbose?.message("got class name \(className)")
                var cards = [String: Int]()

                for clazz in ["class-listing", "neutral-listing"] {
                    let cardNodes = doc.xpath("//*[contains(@class, '\(clazz)')]//td[contains(@class, 'col-name')]//a")
                    for cardNode in cardNodes {
                        let card: String? = cardNode.text?.trim()
                        var count: Int?
                        if let dataCount = cardNode["data-count"] {
                            count = Int(dataCount)
                        }

                        if let card = card, count = count {
                            Log.verbose?.message("got card \(card.trim()) with count \(count)")
                            if let _card = Cards.byEnglishName(card.trim()) {
                                cards[_card.cardId] = count
                                Log.verbose?.message("Got card \(_card)")
                            }
                        }
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