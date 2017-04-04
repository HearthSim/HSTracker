//
//  FileImporter.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 3/04/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import CleanroomLogger
import RegexUtil

struct FileImporter: BaseFileImporter {

    func fileImport(url: URL) -> (Deck, [Card])? {
        let deckName = url.lastPathComponent.replace("\\.txt$", with: "")
        Log.verbose?.message("Got deck name \(deckName)")

        var isArena = false

        let fileContent: [String]?
        do {
            let content = try NSString(contentsOf: url, encoding: String.Encoding.utf8.rawValue)
            fileContent = content.components(separatedBy: CharacterSet.newlines)
        } catch let error {
            Log.error?.message("\(error)")
            return nil
        }

        guard let lines = fileContent else {
            Log.error?.message("Card list not found")
        }

        let deck = Deck()
        deck.name = deckName

        var cards: [Card] = []
        let regex: RegexPattern = "(\\d)(\\s|x)?([\\w\\s'\\.:!-]+)"
        for line in lines {
            guard !line.isBlank else { continue }

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
                        cards.append(card)
                    }
                }
            }
        }
        deck.isArena = isArena

        guard deck.playerClass != .neutral else {
            Log.error?.message("Class not found")
            return nil
        }

        return (deck, cards)
    }
}
