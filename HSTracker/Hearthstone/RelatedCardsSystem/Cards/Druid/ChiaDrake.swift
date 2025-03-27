//
//  ChiaDrake.swift
//  HSTracker
//
//  Created by Francisco Moraes on 3/20/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class ChiaDrake: ICardWithHighlight {
    required init() {
        
    }
    
    func getCardId() -> String {
        return CardIds.Collectible.Druid.ChiaDrake
    }

    func shouldHighlight(card: Card) -> HighlightColor {
        return HighlightColorHelper.getHighlightColor(card.type == CardType.spell)
    }
}

class ChiaDrakeMini: ChiaDrake {
    override func getCardId() -> String {
        return CardIds.NonCollectible.Druid.ChiaDrake_ChiaDrakeToken
    }
}
