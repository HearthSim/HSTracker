//
//  FandralStaghelm.swift
//  HSTracker
//
//  Created by Francisco Moraes on 3/27/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class FandralStaghelm: ICardWithHighlight {
    required init() {
        
    }
    
    func getCardId() -> String {
        return CardIds.Collectible.Druid.FandralStaghelm
    }

    func shouldHighlight(card: Card, deck: [Card]) -> HighlightColor {
        return HighlightColorHelper.getHighlightColor(card.mechanics.contains("CHOOSE_ONE"))
    }
}

class FandralStaghelmCorePlaceholder: FandralStaghelm {
    override func getCardId() -> String {
        return CardIds.Collectible.Druid.FandralStaghelmCore
    }
}
