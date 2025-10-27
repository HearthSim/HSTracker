//
//  SweetenedSnowflurry.swift
//  HSTracker
//
//  Created by Francisco Moraes on 10/26/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class SweetenedSnowflurry: ICardGenerator {
    func getCardId() -> String {
        return CardIds.Collectible.Neutral.SweetenedSnowflurry
    }

    func isInGeneratorPool(_ card: Card, _ gameMode: GameType, _ format: FormatType) -> Bool {
        return card.type == .spell
            && card.spellSchool == .frost
        && card.isCardLegal(gameType: gameMode, format: format)
    }

    required init() {}
}

class SweetenedSnowflurryMini: SweetenedSnowflurry {
    override func getCardId() -> String {
        return CardIds.NonCollectible.Neutral.SweetenedSnowflurry_SweetenedSnowflurryToken
    }

    required init() {}
}
