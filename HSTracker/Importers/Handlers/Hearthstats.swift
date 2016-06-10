//
//  Hearthstats.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 25/02/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import Kanna
import CleanroomLogger

final class Hearthstats: BaseNetImporter, NetImporterAware {

    var siteName: String {
        return "HearthStats"
    }

    func handleUrl(url: String) -> Bool {
        return url.match("hearthstats\\.net|hss\\.io")
    }

    func loadDeck(url: String, completion: Deck? -> Void) throws {
        let httpsUrl = url.stringByReplacingOccurrencesOfString("http://", withString: "https://")
        loadHtml(httpsUrl) { (html) -> Void in
            if let html = html, doc = Kanna.HTML(html: html, encoding: NSUTF8StringEncoding) {
                var playerClass: String?
                if let node = doc.at_xpath("//div[contains(@class,'win-count')]//img") {
                    if let alt = node["alt"] {
                        playerClass = alt.lowercaseString
                        Log.verbose?.message("got player class : \(playerClass)")
                    }
                }

                if playerClass == nil {
                    completion(nil)
                    return
                }

                var deckName: String?
                if let node = doc.at_xpath("//h1[contains(@class,'page-title')]") {
                    if let name = node.innerHTML?.characters.split("<").map(String.init) {
                        if let name = name.first {
                            deckName = name
                            Log.verbose?.message("got deck name : \(name)")
                        }
                    }
                }
                var cards = [String: Int]()
                for node in doc.xpath("//div[contains(@class,'cardWrapper')]") {
                    if let card = node.at_xpath("div[@class='name']")?.text,
                        count = node.at_xpath("div[@class='qty']")?.text {
                        Log.verbose?.message("card : \(card) -> count \(count)")
                        if let card = Cards.byEnglishName(card),
                            count = Int(count) {
                            cards[card.id] = count
                        }
                    }
                }

                if self.isCount(cards) {
                    self.saveDeck(deckName, playerClass: playerClass!,
                                  cards: cards, isArena: false, completion: completion)
                    return
                }
            }

            completion(nil)
        }
    }
}
