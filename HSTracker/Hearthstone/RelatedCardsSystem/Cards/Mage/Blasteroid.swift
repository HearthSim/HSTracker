//
//  Blasteroid.swift
//  HSTracker
//
//  Created by Francisco Moraes on 10/27/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

class Blasteroid: ICardGenerator {
    func getCardId() -> String {
        return CardIds.Collectible.Mage.Blasteroid
    }

    func isInGeneratorPool(_ card: Card, _ gameMode: GameType, _ format: FormatType) -> Bool {
        return card.type == .spell &&
        card.spellSchool == .fire &&
        card.isCardLegal(gameType: gameMode, format: format)
    }

    required init() {}
}
