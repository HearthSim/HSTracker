//
//  Arcanologist.swift
//  HSTracker
//
//  Created by Francisco Moraes on 3/24/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class Arcanologist: ICardWithHighlight {
    required init() {}
    
    func getCardId() -> String {
        return CardIds.Collectible.Mage.Arcanologist
    }
    
    func shouldHighlight(card: Card, deck: [Card]) -> HighlightColor {
        return HighlightColorHelper.getHighlightColor(card.mechanics.contains("SECRET"))
    }
}

class ArcanologistCore: Arcanologist {
    override func getCardId() -> String {
        return CardIds.Collectible.Mage.ArcanologistCore
    }
}
