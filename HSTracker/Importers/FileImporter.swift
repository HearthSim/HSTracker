//
//  FileImporter.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 3/04/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import CleanroomLogger

struct FileImporter: BaseFileImporter {

    func fileImport(url: NSURL) -> Deck? {
        let deckName = url.lastPathComponent?.replace("\\.txt$", with: "")
        Log.verbose?.message("Got deck name \(deckName)")

        var isArena = false

        let fileContent: [String]?
        do {
            let content = try NSString(contentsOfURL: url, encoding: NSUTF8StringEncoding)
            fileContent = content
                .componentsSeparatedByCharactersInSet(NSCharacterSet.newlineCharacterSet())
        } catch let error {
            Log.error?.message("\(error)")
            return nil
        }

        guard let lines = fileContent else {
            Log.error?.message("Card list not found")
        }

        let deck = Deck(playerClass: .neutral, name: deckName)

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

                    var card = Cards.by(cardId: cardName)
                    if card == nil {
                        card = Cards.by(englishName: cardName)
                    }
                    if card == nil {
                        card = Cards.by(name: cardName)
                    }

                    if let card = card {
                        if card.playerClass != .neutral && deck.playerClass == .neutral {
                            deck.playerClass = card.playerClass
                            Log.verbose?.message("Got class \(deck.playerClass)")
                        }
                        card.count = count
                        Log.verbose?.message("Got card \(card)")
                        deck.addCard(card)
                    }
                }
            }
        }
        deck.isArena = isArena

        guard deck.playerClass != .neutral else {
            Log.error?.message("Class not found")
            return nil
        }

        return deck
    }
}
