//
//  AlterTime.swift
//  HSTracker
//
//  Created by Francisco Moraes on 11/4/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

class AlterTime: ICardGenerator {
    func getCardId() -> String {
        CardIds.Collectible.Mage.AlterTime
    }

    func isInGeneratorPool(_ card: Card, _ gameMode: GameType, _ format: FormatType) -> Bool {
        card.type == .spell &&
        card.isClass(cardClass: .mage) &&
        card.spellSchool == .arcane &&
        (CardSet.wildSets().contains(card.set ?? .invalid) || CardSet.classicSets().contains(card.set ?? .invalid))
    }

    func isInGeneratorPool(_ card: MultiIdCard, _ gameMode: GameType, _ format: FormatType) -> Bool {
        card.ids.allSatisfy { isInGeneratorPool(Card(id: $0), gameMode, format) }
    }

    required init() {}
}
