//
//  SteamGuardian.swift
//  HSTracker
//
//  Created by Francisco Moraes on 3/24/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

public class SteamGuardian: ICardWithHighlight {
    
    required public init() {
        // Required init, typically empty for now
    }
    
    public func getCardId() -> String {
        return CardIds.Collectible.Warrior.SteamGuardian
    }
    
    func shouldHighlight(card: Card) -> HighlightColor {
        return HighlightColorHelper.getHighlightColor(
            card.spellSchool == SpellSchool.fire,
            card.type == .spell
        )
    }
}
