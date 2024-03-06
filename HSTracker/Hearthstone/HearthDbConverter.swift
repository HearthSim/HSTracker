//
//  HearthDbConverter.swift
//  HSTracker
//
//  Created by Francisco Moraes on 3/2/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class HearthDbConverter {
    static func toHearthDbDeck(deck: MirrorDeck, format: FormatType) -> DeckSerializer.Deck? {
        if let card = Cards.hero(byId: deck.hero), card.dbfId > 0 {
            let result = DeckSerializer.Deck()
            result.name = deck.name
            result.format = format
            result.heroDbfId = card.dbfId
            result.cards = deck.cards.compactMap { x in
                let card = Cards.any(byId: x.cardId)
                card?.count = x.count.intValue
                return card
            }
            // TODO: sideboards
            return result
        }
        return nil
    }
    
    static func toHearthDbDeck(deck: Deck) -> DeckSerializer.Deck? {
        if let card = Cards.hero(byId: deck.heroId), card.dbfId > 0 {
            let result = DeckSerializer.Deck()
            result.name = deck.name
            result.format = deck.guessFormatType()
            result.heroDbfId = card.dbfId
            result.cards = deck.cards.compactMap { x in
                let card = Cards.any(byId: x.id)
                card?.count = x.count
                return card
            }
            // TODO: sideboards
            return result
        }
        return nil
    }
}
