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
            for s in deck.sideboards {
                if let owner = Cards.by(cardId: s.ownerCardId) {
                    var dict = [Int: Int]()
                    for c in s.cards {
                        if let card = Cards.by(cardId: c.id) {
                            dict[card.dbfId] = c.count
                        }
                    }
                    result.sideboards[owner.dbfId] = dict
                }
            }
            return result
        }
        return nil
    }
    
    static func fromHearthDbDeck(deck: DeckSerializer.Deck) -> PlayingDeck {
        var sideboards = [Sideboard]()
        
        for sideboard in deck.sideboards {
            let ownerCardId = Cards.by(dbfId: sideboard.key)!
            let s = Sideboard(ownerCardId: ownerCardId.id, cards: sideboard.value.compactMap { y in
                if let card = Cards.by(dbfId: y.0, collectible: false) {
                    card.count = y.1
                    return card
                }
                return nil
            })
            sideboards.append(s)
        }
        let deck = PlayingDeck(id: "", name: deck.name, hsDeckId: nil, playerClass: Cards.by(dbfId: deck.heroDbfId, collectible: false)?.playerClass ?? .invalid, heroId: "", cards: deck.cards, isArena: false, shortid: "", sideboards: sideboards)
        return deck
    }
}
