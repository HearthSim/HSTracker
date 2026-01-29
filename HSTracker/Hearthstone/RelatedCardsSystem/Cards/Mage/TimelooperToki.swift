//
//  TimelooperToki.swift
//  HSTracker
//
//  Created by Francisco Moraes on 1/28/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

class TimelooperToki: ICardGenerator {
    required init() {}

    func getCardId() -> String {
        return CardIds.Collectible.Mage.TimelooperToki
    }

    func isInGeneratorPool(_ card: Card, _ gameMode: GameType, _ format: FormatType) -> Bool {
        return card.type == .spell &&
        (CardSet.wildSets().contains(card.set ?? .invalid) ||
         CardSet.classicSets().contains(card.set ?? .invalid))
    }

    func isInGeneratorPool(_ card: MultiIdCard, _ gameMode: GameType, _ format: FormatType) -> Bool {
        return card.ids.all { c in
            isInGeneratorPool(Card(id: c), gameMode, format)
        }
    }
}
