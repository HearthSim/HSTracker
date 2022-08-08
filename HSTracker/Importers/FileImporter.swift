//
//  FileImporter.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 3/04/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation

struct FileImporter {

    func fileImport(url: URL) -> (Deck, [Card])? {
        let deckName = url.lastPathComponent.replace("\\.txt$", with: "")
        logger.verbose("Got deck name \(deckName)")

        var isArena = false

        let fileContent: [String]?
        do {
            let content = try NSString(contentsOf: url, encoding: String.Encoding.utf8.rawValue)
            fileContent = content.components(separatedBy: CharacterSet.newlines)
        } catch let error {
            logger.error("\(error)")
            return nil
        }

        guard let lines = fileContent else {
            logger.error("Card list not found")
            return nil
        }

        let deck = Deck()
        deck.name = deckName

        var cards: [Card] = []
        let regex = Regex("(\\d)(\\s|x)?([\\w\\s'\\.:!\\-(),]+)")
        for line in lines {
            guard !line.isBlank else { continue }

            // match "2xMirror Image" as well as "2 Mirror Image" or "2 GVG_002"
            if regex.match(line) {
                let matches = regex.matches(line)
                if matches.count < 3 {
                    continue
                }
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
                            logger.verbose("Got class \(deck.playerClass)")
                        }
                        card.count = count
                        logger.verbose("Got card \(card)")
                        cards.append(card)
                    }
                }
            }
        }
        deck.isArena = isArena

        guard deck.playerClass != .neutral else {
            logger.error("Class not found")
            return nil
        }

        return (deck, cards)
    }
}
