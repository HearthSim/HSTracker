//
//  Insight.swift
//  HSTracker
//
//  Created by Francisco Moraes on 6/23/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class Insight: ICardWithHighlight {
    required init() {}

    func getCardId() -> String {
        CardIds.Collectible.Priest.Insight
    }

    func shouldHighlight(card: Card, deck: [Card]) -> HighlightColor {
        HighlightColorHelper.getHighlightColor(card.type == .minion)
    }
}

class InsightCorrupted: Insight {
    override func getCardId() -> String {
        CardIds.NonCollectible.Priest.Insight_InsightToken
    }
}
