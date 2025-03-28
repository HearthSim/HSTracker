//
//  ExoticHoundmaster.swift
//  HSTracker
//
//  Created by Francisco Moraes on 3/27/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

//swiftlint:disable inclusive_language
class ExoticHoundmaster: ICardWithHighlight {
    required init() {
        
    }
    
    func getCardId() -> String {
        return CardIds.Collectible.Hunter.ExoticHoundmaster
    }
    
    func shouldHighlight(card: Card, deck: [Card]) -> HighlightColor {
        return HighlightColorHelper.getHighlightColor(card.isBeast())
    }
}
//swiftlint:enable inclusive_language
