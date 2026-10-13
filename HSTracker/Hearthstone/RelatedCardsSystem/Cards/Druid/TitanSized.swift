//
//  TitanSized.swift
//  HSTracker
//
//  Created by Francisco Moraes on 10/13/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

// "Draw a minion. Give Beasts in your hand +2/+2."
class TitanSized: ICardWithHighlight {
    required init() {}

    func getCardId() -> String {
        CardIds.Collectible.Druid.TitanSized
    }

    func shouldHighlight(card: Card, deck: [Card]) -> HighlightColor {
        HighlightColorHelper.getHighlightColor(card.type == .minion)
    }
}
