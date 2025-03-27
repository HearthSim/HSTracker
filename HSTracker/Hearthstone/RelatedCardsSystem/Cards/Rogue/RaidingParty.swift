//
//  RaidingParty.swift
//  HSTracker
//
//  Created by Francisco Moraes on 3/24/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class RaidingParty: ICardWithHighlight {
    required init() {}
    
    func getCardId() -> String {
        return CardIds.Collectible.Rogue.RaidingParty
    }
    
    func shouldHighlight(card: Card) -> HighlightColor {
        return HighlightColorHelper.getHighlightColor(card.isPirate(), card.type == .weapon)
    }
}

class RaidingPartyCore: RaidingParty {
    override func getCardId() -> String {
        return CardIds.Collectible.Rogue.RaidingPartyCore
    }
}
