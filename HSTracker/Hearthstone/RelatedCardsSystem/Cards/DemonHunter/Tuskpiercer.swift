//
//  Tuskpiercer.swift
//  HSTracker
//
//  Created by Francisco Moraes on 3/27/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class Tuskpiercer: ICardWithHighlight {
    required init() {
        
    }
    
    func getCardId() -> String {
        return CardIds.Collectible.DemonHunter.Tuskpiercer
    }

    func shouldHighlight(card: Card, deck: [Card]) -> HighlightColor {
        return HighlightColorHelper.getHighlightColor(
            card.type == .minion && card.hasDeathrattle()
        )
    }
}

class TuskpiercerCorePlaceholder: Tuskpiercer {
    override func getCardId() -> String {
        return CardIds.Collectible.DemonHunter.TuskpiercerCore
    }
}
