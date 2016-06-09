//
//  FileImporter.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 3/04/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation

final class FileImporter: BaseNetImporter {

    func fileImport(url: NSURL, completion: Deck? -> Void) {
        let deckName = url.lastPathComponent?.replace("\\.txt$", with: "")
        var className = ""
        var isArena = false
        do {
            let content = try NSString(contentsOfURL: url, encoding: NSUTF8StringEncoding)
            let lines = content
                .componentsSeparatedByCharactersInSet(NSCharacterSet.newlineCharacterSet())

            var cards = [String: Int]()
            let regex = "(\\d)(\\s|x)?([\\w\\s'\\.:!-]+)"
            for line in lines {
                // match "2xMirror Image" as well as "2 Mirror Image" or "2 GVG_002"
                if line.match(regex) {
                    let matches = line.matches(regex)
                    let cardName = matches[2].value.trim()
                    if let count = Int(matches[0].value) {
                        if count > 2 {
                            isArena = true
                        }

                        var card = Cards.byId(cardName)
                        if card == nil {
                            card = Cards.byEnglishName(cardName)
                        }
                        if card == nil {
                            card = Cards.byName(cardName)
                        }

                        if let card = card {
                            if card.playerClass != "" && card.playerClass != "neutral"
                                && String.isNullOrEmpty(className) {
                                className = card.playerClass
                            }

                            cards[card.id] = count
                        }
                    }
                }
            }

            if !String.isNullOrEmpty(className) && self.isCount(cards) {
                saveDeck(deckName, playerClass: className, cards: cards,
                         isArena: isArena, completion: completion)
                return
            }
        } catch {
        }

        // TODO add error
        completion(nil)
    }
}
