//
//  PlumeOfVulcanos.swift
//  HSTracker
//
//  Created by Francisco Moraes on 3/11/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

class PlumeOfVulcanos: ICardGenerator {
    required init() {}

    func getCardId() -> String {
        return CardIds.NonCollectible.Mage.Vulcanos_PlumeOfVulcanosToken1
    }

    func isInGeneratorPool(_ card: Card, _ gameMode: GameType, _ format: FormatType) -> Bool {
        return card.type == .spell &&
               card.spellSchool == SpellSchool.fire &&
        card.isCardLegal(gameType: gameMode, format: format)
    }

    func isInGeneratorPool(_ card: MultiIdCard, _ gameMode: GameType, _ format: FormatType) -> Bool {
        return card.ids.contains { c in
            isInGeneratorPool(Card(id: c), gameMode, format)
        }
    }
}

class PlumeOfVulcanos2: PlumeOfVulcanos {

    override func getCardId() -> String {
        return CardIds.NonCollectible.Mage.Vulcanos_PlumeOfVulcanosToken2
    }
}
