//
//  HearthpwnDeckBuilder.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 25/02/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import Kanna
import CleanroomLogger

final class HearthpwnDeckBuilder: BaseNetImporter, NetImporterAware {

    var siteName: String {
        return "HearthpPwn deckbuilder"
    }

    func handleUrl(url: String) -> Bool {
        return url.match("hearthpwn\\.com\\/deckbuilder")
    }

    func loadDeck(url: String, _ completion: Deck? -> Void) throws {
        loadHtml(url) { (html) -> Void in
            if let html = html, doc = Kanna.HTML(html: html, encoding: NSUTF8StringEncoding) {
                var urlParts = url.characters.split { $0 == "#" }.map(String.init)
                let split = urlParts[0].characters.split { $0 == "/" }.map(String.init)
                guard let playerClass = split.last else {
                    completion(nil)
                    return
                }

                var deckName = ""
                if let node = doc.at_xpath("//div[contains(@class,'deck-name-container')]/h2") {
                    if let name = node.innerHTML {
                        Log.verbose?.message("got deck name : \(name)")
                        deckName = name
                    }
                }

                Log.verbose?.message("\(playerClass)")

                let cardIds = urlParts.last?.characters.split { $0 == ";" }.map(String.init)
                var cards = [String: Int]()
                cardIds?.forEach({ (str) -> () in
                    let split = str.characters.split(":").map(String.init)
                    if let id = split.first,
                        count = Int(split.last!) {
                        if let node = doc.at_xpath("//tr[@data-id='\(id)']/td[1]/b"),
                            cardId = node.text {
                            Log.verbose?.message("id : \(id) count : \(count) text : \(node.text)")
                            if let card = Cards.byEnglishName(cardId) {
                                cards[card.id] = count
                            }
                        }
                    }
                })

                if self.isCount(cards) {
                    self.saveDeck(deckName, playerClass, cards, false, completion)
                    return
                }
            }

            completion(nil)
        }
    }
}
