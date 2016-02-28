//
//  Hearthhead.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 25/02/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import RegExCategories
import Kanna

class Hearthhead: BaseNetImporter, NetImporterAware {
    static let classes = [
        1: "warrior",
        2: "paladin",
        3: "hunter",
        4: "rogue",
        5: "priest",
        7: "shaman",
        8: "mage",
        9: "warlock",
        11: "druid"
    ]
    
    var siteName:String {
        return "Hearthhead"
    }
    
    func handleUrl(url: String) -> Bool {
        return url.isMatch(NSRegularExpression.rx("hearthhead\\.com\\/deck="))
    }
    
    func loadDeck(url: String, _ completion: Deck? -> Void) throws {
        loadHtml(url) { (html) -> Void in
            if let html = html, doc = Kanna.HTML(html: html, encoding: NSUTF8StringEncoding) {
                var className:String?
                if let classNode = doc.at_xpath("//div[@class='deckguide-hero']") {
                    if let clazz = classNode["data-class"], classId = Int(clazz) {
                        className = Hearthhead.classes[classId]
                        DDLogVerbose("found \(className)")
                    }
                }
                var deckName:String?
                if let deckNode = doc.at_xpath("//h1[@id='deckguide-name']") {
                    deckName = deckNode.text?.trim()
                    DDLogVerbose("found \(deckName)")
                }
                
                var cards = [String:Int]()
                for cardNode in doc.xpath("//div[contains(@class,'deckguide-cards-type')]/ul/li") {
                    var cardId:String?
                    if let cardNameNode = cardNode.at_xpath("a"),
                        let cardName = cardNameNode.text,
                        let card = Cards.byEnglishName(cardName) {
                            cardId = card.cardId
                            DDLogVerbose("\(cardName)")
                    }
                    var count = 1
                    if let cardNodeHTML = cardNode.text {
                        if cardNodeHTML.isMatch(NSRegularExpression.rx("x[0-9]+$")) {
                            if let match = cardNodeHTML.firstMatchWithDetails(NSRegularExpression.rx("x([0-9]+)$")) {
                                let qty: String = match.groups[1].value
                                if let _count = Int(qty) {
                                    count = _count
                                }
                            }
                        }
                    }
                    
                    if let cardId = cardId {
                        cards[cardId] = count
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