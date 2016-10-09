//
//  BaseNetImporter.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 25/02/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import Alamofire
import CleanroomLogger

class BaseNetImporter {

    func loadHtml(url: String, completion: String? -> Void) {
        Log.info?.message("Fetching \(url)")
        
        Alamofire.request(.GET, url)
            .responseData() { response in
                
                if let data = response.result.value {
                    var convertedNSString: NSString?
                    NSString.stringEncodingForData(data,
                        encodingOptions: nil,
                        convertedString: &convertedNSString,
                        usedLossyConversion: nil)
                    
                    Log.info?.message("Fetching \(url) complete")
                    let convertedString = convertedNSString as? String
                    completion(convertedString)
                } else {
                    print(response.result.error)
                    completion(nil)
                }
        }
    }

    func loadJson(url: String, parameters: [String: String], completion: Any? -> Void) {
        Log.info?.message("Fetching \(url)")

        Alamofire.request(.GET, url,
            parameters: parameters)
            .responseJSON { response in
                if let data = response.result.value where response.result.isSuccess {
                    Log.info?.message("Fetching \(url) complete")
                    completion(data)
                } else {
                    print(response.result.error)
                    completion(nil)
                }
        }
    }

    func saveDeck(name: String?, playerClass: CardClass, cards: [String:Int],
                  isArena: Bool, completion: Deck? -> Void) {
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
        Decks.instance.add(deck)
        completion(deck)
    }

    func isCount(cards: [String:Int]) -> Bool {
        let count = cards.map {$0.1}.reduce(0, combine: +)
        Log.verbose?.message("counting \(count) cards : \(cards)")
        return count == 30
    }

}
