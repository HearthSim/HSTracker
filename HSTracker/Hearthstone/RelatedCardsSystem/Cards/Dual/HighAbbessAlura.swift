//
//  HighAbbessAlura.swift
//  HSTracker
//
//  Created by Francisco Moraes on 5/22/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class HighAbbessAlura: ICardWithHighlight {
    required init() {}
    
    func getCardId() -> String {
        return CardIds.Collectible.Paladin.HighAbbessAlura
    }

    func shouldHighlight(card: Card, deck: [Card]) -> HighlightColor {
        return HighlightColorHelper.getHighlightColor(card.type == .spell)
    }
}
