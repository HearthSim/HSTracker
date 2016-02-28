//
//  BaseNetImporter.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 25/02/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import Alamofire

class BaseNetImporter {
    
    func loadHtml(url:String, _ completion: String? -> Void) {
        DDLogInfo("Fetching \(url)")
        Alamofire.request(.GET, url)
            .responseString(encoding: NSUTF8StringEncoding) { response in
                if let html = response.result.value {
                    DDLogInfo("Fetching \(url) complete")
                    completion(html)
                }
                else {
                    completion(nil)
                }
        }
    }
    
    func saveDeck(name:String?, _ playerClass:String, _ cards:[String:Int], _ isArena:Bool, _ completion: Deck? -> Void) {
        let deck = Deck(playerClass: playerClass, name: name)
        
        deck.isActive = true
        deck.isArena = isArena
        deck.playerClass = playerClass
        for (cardId, count) in cards {
            if let card = Cards.byId(cardId) {
                card.count = count
                deck.addCard(card)
            }
        }
        deck.save()
        completion(deck)
    }
    
    func isCount(cards:[String:Int]) -> Bool {
        let count = cards.map {$0.1}.reduce(0, combine: +)
        DDLogVerbose("counting \(count) cards")
        return count == 30
    }
    
}