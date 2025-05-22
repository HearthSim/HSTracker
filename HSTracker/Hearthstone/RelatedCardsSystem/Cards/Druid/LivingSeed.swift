//
//  LivingSeed.swift
//  HSTracker
//
//  Created by Francisco Moraes on 5/21/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class LivingSeed: ICardWithHighlight {
    required init() {}
    
    func getCardId() -> String {
        return CardIds.Collectible.Druid.LivingSeedRank1
    }

    func shouldHighlight(card: Card, deck: [Card]) -> HighlightColor {
        return HighlightColorHelper.getHighlightColor(card.isBeast())
    }
}

class LivingSeedRank2: LivingSeed {
    required init() {}
    
    override func getCardId() -> String {
        return CardIds.NonCollectible.Druid.LivingSeedRank1_LivingSeedRank2Token
    }
}

class LivingSeedRank3: LivingSeed {
    required init() {}
    
    override func getCardId() -> String {
        return CardIds.NonCollectible.Druid.LivingSeedRank1_LivingSeedRank3Token
    }
}
