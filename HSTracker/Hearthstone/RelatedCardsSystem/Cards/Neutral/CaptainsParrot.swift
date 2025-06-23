//
//  CaptainsParrot.swift
//  HSTracker
//
//  Created by Francisco Moraes on 6/23/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class CaptainsParrot: ICardWithHighlight {
    required init() {}

    func getCardId() -> String {
        CardIds.Collectible.Neutral.CaptainsParrotLegacy
    }

    func shouldHighlight(card: Card, deck: [Card]) -> HighlightColor {
        HighlightColorHelper.getHighlightColor(card.isPirate())
    }
}

class CaptainsParrotVanilla: CaptainsParrot {
    override func getCardId() -> String {
        CardIds.Collectible.Neutral.CaptainsParrotVanilla
    }
}
