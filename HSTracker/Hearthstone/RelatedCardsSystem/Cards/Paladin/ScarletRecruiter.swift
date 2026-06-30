//
//  ScarletRecruiter.swift
//  HSTracker
//
//  Created by Francisco Moraes on 6/30/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

class ScarletRecruiter: ICardWithHighlight {

    required init() {}

    func getCardId() -> String {
        return CardIds.Collectible.Paladin.ScarletRecruiter
    }

    func shouldHighlight(card: Card, deck: [Card]) -> HighlightColor {
        // C# relational pattern matching: card is { TypeEnum: CardType.MINION, Cost: <= 2 }
        let matchesPattern = card.type == .minion && card.cost <= 2
        return HighlightColorHelper.getHighlightColor(matchesPattern)
    }
}
