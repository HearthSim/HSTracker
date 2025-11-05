//
//  Chronogor.swift
//  HSTracker
//
//  Created by Francisco Moraes on 11/4/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

class Chronogor: ICardWithHighlight {
    func getCardId() -> String {
        CardIds.Collectible.Warlock.Chronogor
    }

    func shouldHighlight(card: Card, deck: [Card]) -> HighlightColor {
        let highestCosts = deck.sorted { $0.cost > $1.cost }.prefix(2).map { $0.cost }
        let lowestCosts = deck.sorted { $0.cost < $1.cost }.prefix(2).map { $0.cost }

        return HighlightColorHelper.getHighlightColor(
            highestCosts.contains(card.cost),
            lowestCosts.contains(card.cost)
        )
    }

    required init() {}
}
