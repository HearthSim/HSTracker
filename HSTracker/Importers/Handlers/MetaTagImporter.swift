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

struct MetaTagImporter: HttpImporter {
    var siteName: String { return "" }
    var handleUrl: String { return ".*" }

    func loadDeck(doc: HTMLDocument, url: String) -> Deck? {
        let nodes = doc.xpath("//meta")
        guard let heroId = getMetaProperty(nodes: nodes, prop: "x-hearthstone:deck:hero"),
            let playerClass = Cards.hero(byId: heroId)?.playerClass else {
                Log.error?.message("Class not found")
                return nil
        }
        Log.verbose?.message("Got class \(playerClass)")
        
        guard let deckName = getMetaProperty(nodes: nodes, prop: "x-hearthstone:deck") else {
            Log.error?.message("Deck name not found")
            return nil
        }
        Log.verbose?.message("Got deck name \(deckName)")

        let deck = Deck(playerClass: playerClass, name: deckName)

        guard let cardList = getMetaProperty(nodes: nodes, prop: "x-hearthstone:deck:cards")?
            .components(separatedBy: ",") else {
                Log.error?.message("Card list not found")
                return nil
        }
        for cardId in cardList {
            if let card = Cards.by(cardId: cardId) {
                Log.verbose?.message("Got card \(card)")
                deck.add(card: card)
            }
        }
        return deck
    }
    
    private func getMetaProperty(nodes: XPathObject, prop: String) -> String? {
        return nodes.filter({ $0["property"] ?? "" == prop }).first?["content"]
    }
    
}
