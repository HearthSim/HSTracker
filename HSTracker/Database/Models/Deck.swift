//
//  Deck.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 19/02/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import CoreData
import MagicalRecord

@objc(Deck)
class Deck: NSManagedObject {

    @NSManaged var hearthstatsId: Int64
    @NSManaged var hearthstatsVersionId: Int64
    @NSManaged var isActive: Bool
    @NSManaged var isArena: Bool
    @NSManaged var name: String
    @NSManaged var playerClass: String
    @NSManaged var version: String
    @NSManaged var deckCards: Set<DeckCard>
    
    var cards:[Card]?
    
    var sortedCards: [Card] {
        if let cards = self.cards {
            return cards
        }
        else {
            var cards = [Card]()
            for deckCard in deckCards {
                if let card = Cards.byId(deckCard.cardId) {
                    card.count = deckCard.count
                    cards.append(card)
                }
            }
            cards = cards.sortCardList()
            self.cards = cards
            return cards
        }
    }

    func displayStats() -> String {
        // TODO
        return "12 - 1 / 97%"
    }
}
