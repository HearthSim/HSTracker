//
//  MetaTagImporter.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 28/08/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import Kanna
import CleanroomLogger

class MetaTagImporter: BaseNetImporter {
    
    func loadDeck(url: String, completion: Deck? -> Void) throws {
        loadHtml(url) { (html) -> Void in
            guard let html = html,
                doc = Kanna.HTML(html: html, encoding: NSUTF8StringEncoding) else {
                    completion(nil)
                    return
            }
            let nodes = doc.xpath("//meta")
            guard let heroId = self.getMetaProperty(nodes, prop: "x-hearthstone:deck:hero"),
                playerClass = Cards.hero(byId: heroId) else {
                    // can't find class, ignore
                    Log.error?.message("class not found")
                    completion(nil)
                    return
            }
            Log.info?.message("Found class \(playerClass)")
            guard let deckName = self.getMetaProperty(nodes, prop: "x-hearthstone:deck") else {
                // can't find class, ignore
                Log.error?.message("name not found")
                completion(nil)
                return
            }
            
            Log.verbose?.message("\(playerClass) \(deckName)")
            guard let cardList = self.getMetaProperty(nodes, prop: "x-hearthstone:deck:cards")?
                .componentsSeparatedByString(",") else {
                    Log.error?.message("card list not found")
                    completion(nil)
                    return
            }
            var cards = [String: Int]()
            for cardId in cardList {
                if cards.keys.contains(cardId) {
                    cards[cardId] = cards[cardId]! + 1
                } else {
                    cards[cardId] = 1
                }
            }
            
            if self.isCount(cards) {
                self.saveDeck(deckName, playerClass: playerClass.playerClass,
                              cards: cards, isArena: false,
                              completion: completion)
                return
            }
            
            completion(nil)
        }
    }
    
    private func getMetaProperty(nodes: XPathObject, prop: String) -> String? {
        return nodes.filter({ $0["property"] ?? "" == prop }).first?["content"]
    }
    
}
