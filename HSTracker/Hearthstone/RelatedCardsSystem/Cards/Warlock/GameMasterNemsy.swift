//
//  GameMasterNemsy.swift
//  HSTracker
//
//  Created by Francisco Moraes on 3/24/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

//swiftlint:disable inclusive_language
class GameMasterNemsy: ICardWithHighlight {
    required init() {}
    
    func getCardId() -> String {
        return CardIds.Collectible.Warlock.GameMasterNemsy
    }
    
    func shouldHighlight(card: Card) -> HighlightColor {
        return HighlightColorHelper.getHighlightColor(card.isDemon())
    }
}
//swiftlint:enable inclusive_language
