//
//  ElvenMinstrel.swift
//  HSTracker
//
//  Created by Francisco Moraes on 3/24/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class ElvenMinstrel: ICardWithHighlight {
    required init() {}
    
    func getCardId() -> String {
        return CardIds.Collectible.Rogue.ElvenMinstrel
    }
    
    func shouldHighlight(card: Card) -> HighlightColor {
        return HighlightColorHelper.getHighlightColor(card.type == .minion)
    }
}

class ElvenMinstrelCore: ElvenMinstrel {
    override func getCardId() -> String {
        return CardIds.Collectible.Rogue.ElvenMinstrelCore
    }
}
