//
//  BaseNetImporter.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 25/02/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import Alamofire
import MagicalRecord

class BaseNetImporter {
    
    func loadHtml(url:String, _ completion: String? -> Void) {
        DDLogInfo("Fetching \(url)")
        Alamofire.request(.GET, url)
            .responseString { response in
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
        MagicalRecord.saveWithBlock { (context) -> Void in
            if let deck = Deck.MR_createEntityInContext(context) {
                if let name = name {
                    deck.name = name
                }
                deck.isActive = true
                deck.isArena = isArena
                deck.playerClass = playerClass
                for (cardId, count) in cards {
                    if let deckCard = DeckCard.MR_createEntityInContext(context) {
                        deckCard.cardId = cardId
                        deckCard.count = count
                        deck.deckCards.insert(deckCard)
                    }
                }
                completion(deck)
            }
            else {
                completion(nil)
            }
        }
    }
    
    func isCount(cards:[String:Int]) -> Bool {
        var count:Int = 0
        for (_,c) in cards {
            count += c
        }
        
        return count == 30
    }
    
}