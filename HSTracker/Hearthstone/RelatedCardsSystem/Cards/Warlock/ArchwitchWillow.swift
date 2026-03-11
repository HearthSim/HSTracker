//
//  ArchwitchWillow.swift
//  HSTracker
//
//  Created by Francisco Moraes on 5/22/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class ArchwitchWillow: ICardWithHighlight {
    required init() {}

    func getCardId() -> String {
        return CardIds.Collectible.Warlock.ArchwitchWillow
    }

    func shouldHighlight(card: Card, deck: [Card]) -> HighlightColor {
        return HighlightColorHelper.getHighlightColor(card.isDemon())
    }
}

class ArchwitchWillowCorePlaceholder: ArchwitchWillow {

    override func getCardId() -> String {
        return CardIds.Collectible.Warlock.ArchwitchWillowCorePlaceholder
    }
}
