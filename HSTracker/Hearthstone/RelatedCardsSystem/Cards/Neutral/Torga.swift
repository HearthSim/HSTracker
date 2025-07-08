//
//  Torga.swift
//  HSTracker
//
//  Created by Francisco Moraes on 7/7/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class Torga: ICardWithHighlight {
    required init() {
        
    }
    
    func getCardId() -> String {
        CardIds.Collectible.Neutral.Torga
    }

    func shouldHighlight(card: Card, deck: [Card]) -> HighlightColor {
        let kindreds = deck.filter { $0.mechanics.contains("KINDRED") }

        let isMinionKindredTarget = card.type == .minion &&
            kindreds.filter { $0.type == .minion }
            .flatMap { $0.races }.compactMap { $0 }.filter { $0 != .invalid }.any { card.hasRace($0) }
        
        let isSpellKindredTarget = card.type == .spell &&
            kindreds.filter { $0.type == .spell }
                .compactMap { $0.spellSchool }
                .filter { $0 != .none }.any { card.spellSchool == $0 }

        return HighlightColorHelper.getHighlightColor(
            card.mechanics.contains("KINDRED"),
            isMinionKindredTarget || isSpellKindredTarget
        )
    }
}
