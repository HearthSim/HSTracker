//
//  Banjosaur.swift
//  HSTracker
//
//  Created by Francisco Moraes on 3/21/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

class Banjosaur: ICardWithHighlight {
    func getCardId() -> String {
        return CardIds.Collectible.Hunter.Banjosaur
    }

    func shouldHighlight(card: Card, deck: [Card]) -> HighlightColor {
        return HighlightColorHelper.getHighlightColor(card.isBeast())
    }

    required init() {}
}
