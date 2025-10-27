//
//  FiddlefireImp.swift
//  HSTracker
//
//  Created by Francisco Moraes on 10/26/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class FiddlefireImp: ICardGenerator {
    func getCardId() -> String {
        return CardIds.Collectible.Warlock.FiddlefireImp
    }

    func isInGeneratorPool(_ card: Card, _ gameMode: GameType, _ format: FormatType) -> Bool {
        return card.type == .spell &&
        card.spellSchool == .fire &&
        (card.isClass(cardClass: .mage) || card.isClass(cardClass: .warlock)) &&
        card.isCardLegal(gameType: gameMode, format: format)
    }

    required init() {}
}
