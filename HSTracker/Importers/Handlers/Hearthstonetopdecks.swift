//
//  Hearthstonetopdecks.swift
//  HSTracker
//
//  Created by Istvan Fehervari on 29/08/16.
//  Copyright © 2016 Istvan Fehervari. All rights reserved.
//

import Foundation
import Kanna
import CleanroomLogger

final class Hearthstonetopdecks: BaseNetImporter, NetImporterAware {
    
    var siteName: String {
        return "Hearthstonetopdecks"
    }
    
    func handleUrl(url: String) -> Bool {
        return url.match("hearthstonetopdecks\\.com\\/decks")
    }
    
    func loadDeck(url: String, completion: Deck? -> Void) throws {
        loadHtml(url) { (html) -> Void in
            if let html = html, doc = Kanna.HTML(html: html, encoding: NSUTF8StringEncoding) {
                var deckName: String?
                if let nameNode = doc.at_xpath("//h1[contains(@class, 'entry-title')]") {
                    if let name = nameNode.text {
                        deckName = name
                    }
                }
                Log.verbose?.message("got deck name \(deckName)")
                
                var className: String?
                // swiftlint:disable line_length
                if let classNode = doc.at_xpath("//div[contains(@class, 'deck-info')]/a[contains(@href, 'deck-class') ]") {
                    // swiftlint:enable line_length
                    if let clazz = classNode.text {
                        className = clazz.trim()
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
                
                let xpath = "//*[contains(@class, 'deck-class')]/li/a"
                let cardNodes = doc.xpath(xpath)
                for cardNode in cardNodes {
                    if let card = cardNode.at_xpath("span[@class='card-name']")?.text,
                        cardcountstr = cardNode.at_xpath("span[@class='card-count']")?.text,
                        count = Int(cardcountstr) {
                        Log.verbose?.message("got card \(card.trim()) with count \(count)")
                        
                        // Hearthstonetopdeck sport several cards with wrong capitalization
                        // (e.g. N'Zoth)

                        let fixedcardname = card.trim()
                            .stringByReplacingOccurrencesOfString("’", withString: "'")
                        
                        if let _card = Cards.byEnglishNameCaseInsensitive(fixedcardname) {
                            Log.verbose?.message("Got card \(_card)")
                            cards[_card.id] = count
                        } else {
                            print("Failed to import card \(card)")
                        }
                    }
                }
                
                if let className = className,
                    playerClass = CardClass(rawValue: className.uppercaseString)
                    // check if there are exactly 30 cards in the deck
                    where self.isCount(cards) {
                    self.saveDeck(deckName, playerClass: playerClass,
                                  cards: cards, isArena: false,
                                  completion: completion)
                    return
                }
            }
            
            completion(nil)
        }
    }
}
