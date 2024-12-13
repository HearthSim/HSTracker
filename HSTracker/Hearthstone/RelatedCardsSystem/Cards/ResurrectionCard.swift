//
//  ResurrectionCard.swift
//  HSTracker
//
//  Created by Francisco Moraes on 12/13/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class ResurrectionCard: ICardWithRelatedCards {
    required init() {
        
    }
    
    // Abstract method for getting the card ID
    func getCardId() -> String {
        fatalError("This method must be overridden in a subclass")
    }

    // Default implementation: Don't usually show these cards for the opponent
    func shouldShowForOpponent(opponent: Player) -> Bool {
        return false
    }

    // Abstract method for filtering the card
    func filterCard(card: Card) -> Bool {
        fatalError("This method must be overridden in a subclass")
    }

    // Abstract method to check if the card resurrects multiple cards
    func resurrectsMultipleCards() -> Bool {
        fatalError("This method must be overridden in a subclass")
    }

    // Method for retrieving related cards (resurrected cards from dead minions)
    func getRelatedCards(player: Player) -> [Card?] {
        var cards = player.deadMinionsCards
            .compactMap { CardUtils.getProcessedCardFromEntity($0, player) }
            .filter { card in
                return filterCard(card: card)
            }

        if !resurrectsMultipleCards() {
            // If the card resurrects only one card, eliminate duplicates
            cards = cards.unique()
        }

        // The order isn't typically relevant, so we sort by cost in descending order
        return cards.sorted { $0.cost > $1.cost }
    }
}
