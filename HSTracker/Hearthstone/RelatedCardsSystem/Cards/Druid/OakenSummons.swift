//
//  OakenSummons.swift
//  HSTracker
//
//  Created by Francisco Moraes on 3/20/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class OakenSummons: ICardWithHighlight {
    required init() {
        
    }
    
    func getCardId() -> String {
        return CardIds.Collectible.Druid.OakenSummons
    }

    func shouldHighlight(card: Card, deck: [Card]) -> HighlightColor {
        return HighlightColorHelper.getHighlightColor(card.type == CardType.minion && card.cost <= 4)
    }
}

class OakenSummonsCore: OakenSummons {
    override func getCardId() -> String {
        return CardIds.Collectible.Druid.OakenSummonsCore
    }
}
