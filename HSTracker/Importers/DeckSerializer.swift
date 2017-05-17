//
//  DeckSerializer.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 17/05/17.
//  Copyright © 2017 Benjamin Michotte. All rights reserved.
//

import Foundation
import CleanroomLogger

class DeckSerializer {
    enum DeckSerializerError: Error {
        case argumentError
    }

    struct SerializedDeck {
        let name: String
        let playerClass: CardClass
        let cards: [Card]
    }

    class func deserialize(input: String) -> SerializedDeck? {
        let lines = input.components(separatedBy: .newlines).map {
            $0.trim()
        }

        var deckName: String?
        var playerClass: CardClass?
        var cards: [Card]?

        for line in lines {
            if line.isBlank { continue }

            if line.hasPrefix("#") {
                if line.hasPrefix("###") {
                    deckName = line.substring(from: 3).trim()
                }

                continue
            }

            if let (_cardClass, _cards) = deserializeDeckString(deckString: line) {
                playerClass = _cardClass
                cards = _cards
            }
        }

        guard let _deckName = deckName,
            let _playerClass = playerClass,
            let _cards = cards else { return nil }

        return SerializedDeck(name: _deckName,
                              playerClass: _playerClass,
                              cards: _cards)
    }

    class func deserializeDeckString(deckString: String) -> (CardClass, [Card])? {
        guard let data = Data(base64Encoded: deckString) else {
            Log.error?.message("Can not decode \(deckString)")
            return nil
        }

        var bytes = [UInt8](data)

        var offset = 0
        @discardableResult func read() throws -> Varint {
            if offset > bytes.count {
                throw DeckSerializerError.argumentError
            }
            guard let value = Varint.VarintFromBytes(Array(bytes[offset..<bytes.count])) else {
                throw DeckSerializerError.argumentError
            }
            offset += value.count
            return value
        }

        // Zero byte
        offset += 1

        // Version - currently unused, always 1
        _ = try? read()

        // Format - determined dynamically
        _ = try? read()

        // Num Heroes - always 1
        _ = try? read()

        guard let heroId = try? read() else {
            Log.error?.message("Can not get heroId")
            return nil
        }
        guard let heroCard = Cards.by(dbfId: Int(heroId.toInt64()), collectible: false) else {
            Log.error?.message("Can not get heroCard")
            return nil
        }
        let cardClass = heroCard.playerClass
        Log.verbose?.message("Got class \(cardClass)")

        var cards: [Card] = []
        func addCard(dbfId: Varint? = nil, count: Int = 1) {
            let dbfId = dbfId ?? (try? read())
            guard let id = dbfId,
                let card = Cards.by(dbfId: Int(id.toInt64())) else {
                    Log.error?.message("Can not get card")
                    return
            }
            Log.verbose?.message("**** got card \(card.id) * \(count)")

            card.count = count
            cards.append(card)
        }

        let numSingleCards = Int((try? read())?.toUInt64() ?? 0)
        Log.verbose?.message("numSingleCards : \(numSingleCards)")
        for _ in 0..<numSingleCards {
            addCard()
        }

        let numDoubleCards = Int((try? read())?.toUInt64() ?? 0)
        Log.verbose?.message("numDoubleCards : \(numDoubleCards)")
        for _ in 0..<numDoubleCards {
            addCard(count: 2)
        }

        let numMultiCards = Int((try? read())?.toUInt64() ?? 0)
        Log.verbose?.message("numMultiCards : \(numMultiCards)")
        for _ in 0..<numMultiCards {
            let dbfId = try? read()
            let count = Int((try? read())?.toInt64() ?? 1)
            addCard(dbfId: dbfId, count: count)
        }

        return (cardClass, cards)
    }

    class func serialize(deck: Deck) -> String? {
        guard let hero = Cards.hero(byId: deck.heroId)
            ?? Cards.hero(byPlayerClass: deck.playerClass) else {
                Log.error?.message("Deck has no hero")
                return nil
        }

        let heroDbfId = hero.dbfId
        var data = Data()

        func write(value: Int) {
            let varint = Varint(fromValue: Int64(value))
            data.append(contentsOf: varint.backing)
        }

        data.append(contentsOf: [0])
        write(value: 1)
        write(value: deck.isWildDeck ? 1 : 2)
        write(value: 1)
        write(value: heroDbfId)
        let cards = deck.sortedCards.sorted(by: {
            return $0.0.dbfId < $0.1.dbfId
        })
        let singleCards = cards.filter({ $0.count == 1 })
        let doubleCards = cards.filter({ $0.count == 2 })
        let multiCards = cards.filter({ $0.count > 2 })

        write(value: singleCards.count)
        for card in singleCards {
            write(value: card.dbfId)
        }

        write(value: doubleCards.count)
        for card in doubleCards {
            write(value: card.dbfId)
        }

        write(value: multiCards.count)
        for card in multiCards {
            write(value: card.dbfId)
            write(value: card.count)
        }

        return data.base64EncodedString()
    }
}
