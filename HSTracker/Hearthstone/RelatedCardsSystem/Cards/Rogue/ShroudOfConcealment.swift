//
//  ShroudOfConcealment.swift
//  HSTracker
//
//  Created by Francisco Moraes on 11/29/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

class ShroudOfConcealment: ICardWithHighlight {
    required init() {
        
    }
    
    func getCardId() -> String {
        CardIds.Collectible.Rogue.ShroudOfConcealment
    }

    func shouldHighlight(card: Card, deck: [Card]) -> HighlightColor {
        HighlightColorHelper.getHighlightColor(card.type == .minion)
    }
}
