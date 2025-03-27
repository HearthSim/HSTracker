//
//  MysteryEgg.swift
//  HSTracker
//
//  Created by Francisco Moraes on 3/24/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class MysteryEgg: ICardWithHighlight {
    required init() {}
    
    func getCardId() -> String {
        return CardIds.Collectible.Hunter.MysteryEgg
    }
    
    func shouldHighlight(card: Card) -> HighlightColor {
        return HighlightColorHelper.getHighlightColor(card.isBeast())
    }
}

class MysteryEggMini: MysteryEgg {
    override func getCardId() -> String {
        return CardIds.NonCollectible.Hunter.MysteryEgg_MysteryEggToken
    }
}
