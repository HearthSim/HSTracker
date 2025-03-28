//
//  SummerFlowerchild.swift
//  HSTracker
//
//  Created by Francisco Moraes on 3/20/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class SummerFlowerchild: ICardWithHighlight {
    required init() {
        
    }
    
    func getCardId() -> String {
        return CardIds.Collectible.Druid.SummerFlowerchild
    }

    func shouldHighlight(card: Card, deck: [Card]) -> HighlightColor {
        return HighlightColorHelper.getHighlightColor(card.cost >= 6)
    }
}
