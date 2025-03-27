//
//  InterstellarResearcher.swift
//  HSTracker
//
//  Created by Francisco Moraes on 3/24/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class InterstellarResearcher: ICardWithHighlight {
    private let libramCardIds: [String] = [
        CardIds.Collectible.Paladin.LibramOfWisdom,
        CardIds.Collectible.Paladin.LibramOfClarity,
        CardIds.Collectible.Paladin.LibramOfDivinity,
        CardIds.Collectible.Paladin.LibramOfJustice,
        CardIds.Collectible.Paladin.LibramOfFaith,
        CardIds.Collectible.Paladin.LibramOfJudgment,
        CardIds.Collectible.Paladin.LibramOfHope
    ]
    
    required init() {}
    
    func getCardId() -> String {
        return CardIds.Collectible.Paladin.InterstellarResearcher
    }
    
    func shouldHighlight(card: Card) -> HighlightColor {
        return HighlightColorHelper.getHighlightColor(
            libramCardIds.contains(card.id)
        )
    }
}
