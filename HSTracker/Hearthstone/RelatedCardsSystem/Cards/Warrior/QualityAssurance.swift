//
//  QualityAssurance.swift
//  HSTracker
//
//  Created by Francisco Moraes on 3/24/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class QualityAssurance: ICardWithHighlight {
    required init() {}

    func getCardId() -> String {
        return CardIds.Collectible.Warrior.QualityAssurance
    }

    func shouldHighlight(card: Card) -> HighlightColor {
        return HighlightColorHelper.getHighlightColor(card.type == .minion && card.mechanics.contains("TAUNT"))
    }
}
