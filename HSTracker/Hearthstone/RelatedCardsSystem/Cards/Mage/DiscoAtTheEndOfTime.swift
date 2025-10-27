//
//  DiscoAtTheEndOfTime.swift
//  HSTracker
//
//  Created by Francisco Moraes on 10/27/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

class DiscoAtTheEndOfTime: ICardGenerator {
    func getCardId() -> String {
        return CardIds.Collectible.Mage.DiscoAtTheEndOfTime
    }

    func isInGeneratorPool(_ card: Card, _ gameMode: GameType, _ format: FormatType) -> Bool {
        return card.mechanics.contains("SECRET") &&
        (CardSet.wildSets().contains(card.set ?? .invalid) ||
         CardSet.classicSets().contains(card.set ?? .invalid))
    }

    func isInGeneratorPool(_ card: MultiIdCard, _ gameMode: GameType, _ format: FormatType) -> Bool {
        return card.ids.any { c in isInGeneratorPool(Card(id: c), gameMode, format) }
    }
    
    required init() {}
}
