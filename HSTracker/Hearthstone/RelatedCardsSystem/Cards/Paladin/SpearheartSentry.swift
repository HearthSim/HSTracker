//
//  SpearheartSentry.swift
//  HSTracker
//
//  Created by Francisco Moraes on 3/11/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

class SpearheartSentry: ICardGenerator {

    required init() {}

    func getCardId() -> String {
        return CardIds.Collectible.Paladin.SpearheartSentry
    }

    func isInGeneratorPool(_ card: Card, _ gameMode: GameType, _ format: FormatType) -> Bool {
        return card.type == .spell &&
               card.spellSchool == SpellSchool.holy &&
        card.isCardLegal(gameType: gameMode, format: format)
    }

    func isInGeneratorPool(_ card: MultiIdCard, _ gameMode: GameType, _ format: FormatType) -> Bool {
        return card.ids.contains { c in
            isInGeneratorPool(Card(id: c), gameMode, format)
        }
    }
}
