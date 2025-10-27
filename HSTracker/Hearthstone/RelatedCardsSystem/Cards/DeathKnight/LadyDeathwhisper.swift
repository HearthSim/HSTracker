//
//  LadyDeathwhisper.swift
//  HSTracker
//
//  Created by Francisco Moraes on 10/27/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

class LadyDeathwhisper: ICardGenerator {
    func getCardId() -> String {
        return CardIds.Collectible.Deathknight.LadyDeathwhisper
    }

    func isInGeneratorPool(_ card: Card, _ gameMode: GameType, _ format: FormatType) -> Bool {
        return card.type == .spell &&
        card.spellSchool == .frost &&
        card.isCardLegal(gameType: gameMode, format: format)
    }

    required init() {}
}
