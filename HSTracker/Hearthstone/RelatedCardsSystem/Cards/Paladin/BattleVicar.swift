//
//  BattleVicar.swift
//  HSTracker
//
//  Created by Francisco Moraes on 10/26/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class BattleVicar: ICardGenerator {
    func getCardId() -> String {
        return CardIds.Collectible.Paladin.BattleVicar
    }

    func isInGeneratorPool(_ card: Card, _ gameMode: GameType, _ format: FormatType) -> Bool {
        return card.type == .spell
            && card.spellSchool == .holy
        && card.isCardLegal(gameType: gameMode, format: format)
    }

    required init() {}
}
