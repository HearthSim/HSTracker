//
//  UndeathSentence.swift
//  HSTracker
//
//  Created by Francisco Moraes on 6/30/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

class UndeathSentence: ResurrectionCard {

    override func getCardId() -> String {
        return CardIds.Collectible.Priest.UndeathSentence
    }

    override func filterCard(card: Card) -> Bool {
        return card.hasDeathrattle()
    }

    override func resurrectsMultipleCards() -> Bool {
        return false
    }
}
