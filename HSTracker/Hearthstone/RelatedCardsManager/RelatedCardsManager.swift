//
//  RelatedCardsManager.swift
//  HSTracker
//
//  Created by Francisco Moraes on 11/5/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class RelatedCardsManager {
    private var cards = [String: ICardWithRelatedCards]()

    private func initialize() {
        let _cards = ReflectionHelper.getRelatedClases()

        for card in _cards {
            let cardWithRelatedCarts = card.init()
            cards[cardWithRelatedCarts.getCardId()] = cardWithRelatedCarts
        }
    }

    public func reset() {
        if cards.count == 0 {
            initialize()
        }
    }

    public func getCardWithRelatedCards(_ cardId: String) -> ICardWithRelatedCards {
        return cards[cardId] ?? cards[""]!
    }

    public func getCardsOpponentMayHave(_ opponent: Player) -> [Card] {
        return cards.values.filter { card in card.shouldShowForOpponent(opponent: opponent) }
                .compactMap { card in Cards.by(cardId: card.getCardId()) }
    }
}
