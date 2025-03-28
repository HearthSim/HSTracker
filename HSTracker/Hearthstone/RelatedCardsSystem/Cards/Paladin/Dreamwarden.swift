//
//  Dreamwarden.swift
//  HSTracker
//
//  Created by Francisco Moraes on 3/27/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

public class Dreamwarden: ICardWithHighlight {
    
    public required init() { }
    
    public func getCardId() -> String {
        return CardIds.Collectible.Paladin.Dreamwarden
    }
    
    func shouldHighlight(card: Card, deck: [Card]) -> HighlightColor {
        return HighlightColorHelper.getHighlightColor(card.isCreated)
    }
}
