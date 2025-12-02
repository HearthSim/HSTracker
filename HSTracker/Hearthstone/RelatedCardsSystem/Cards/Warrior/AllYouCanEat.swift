//
//  AllYouCanEat.swift
//  HSTracker
//
//  Created by Francisco Moraes on 12/2/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

class AllYouCanEat: ICardWithHighlight {
    required init() {
        
    }
    
    func getCardId() -> String {
        CardIds.Collectible.Warrior.AllYouCanEat
    }

    func shouldHighlight(card: Card, deck: [Card]) -> HighlightColor {
        HighlightColorHelper.getHighlightColor(
            card.type == .minion && !card.isEmptyRace()
        )
    }
}
