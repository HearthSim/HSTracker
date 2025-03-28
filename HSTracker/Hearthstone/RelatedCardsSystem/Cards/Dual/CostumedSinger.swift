//
//  CostumedSinger.swift
//  HSTracker
//
//  Created by Francisco Moraes on 3/21/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

class CostumedSinger: ICardWithHighlight {
    func getCardId() -> String {
        return CardIds.Collectible.Mage.CostumedSinger
    }

    func shouldHighlight(card: Card, deck: [Card]) -> HighlightColor {
        return HighlightColorHelper.getHighlightColor(card.mechanics.contains("SECRET"))
    }

    required init() {}
}
