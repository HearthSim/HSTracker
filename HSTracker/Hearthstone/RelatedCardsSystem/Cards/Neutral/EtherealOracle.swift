//
//  EtherealOracle.swift
//  HSTracker
//
//  Created by Francisco Moraes on 3/24/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class EtherealOracle: ICardWithHighlight {
    required init() {}
    
    func getCardId() -> String {
        return CardIds.Collectible.Neutral.EtherealOracle
    }
    
    func shouldHighlight(card: Card) -> HighlightColor {
        return HighlightColorHelper.getHighlightColor(card.type == .spell)
    }
}
