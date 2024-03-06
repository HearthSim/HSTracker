//
//  DeckSerializer.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 17/05/17.
//  Copyright © 2017 Benjamin Michotte. All rights reserved.
//

import Foundation

class DeckSerializer {
    enum DeckSerializerError: Error {
        case argumentError
    }
    
    class Deck {
        var heroDbfId = 0
        var cards = [Card]()
        var format = FormatType.ft_unknown
        var name = ""
        var deckId = Int64(0)
        
        func getHero() -> Card? {
            return Cards.by(dbfId: heroDbfId, collectible: false)
        }
    }

    static func deserialize(input: String) -> Deck? {
        let lines = input.components(separatedBy: .newlines).map {
            $0.trim()
        }

        var deck: Deck?
        var deckName: String?
        var deckId: String?

        for line in lines {
            if line.isBlank { continue }

            if line.hasPrefix("#") {
                if line.hasPrefix("###") {
                    deckName = line.substring(from: 3).trim()
                }
                if line.hasPrefix("# Deck ID:") {
                    deckId = line.substring(from: 10).trim()
                }

                continue
            }

            if deck == nil {
                deck = deserializeDeckString(deckString: line)
            }
        }
        
        if let deck {
            deck.name = deckName ?? "Imported Deck"
            deck.deckId = Int64(deckId ?? "0") ?? 0
        }
        return deck
    }

    static func deserializeDeckString(deckString: String) -> Deck? {
        guard let data = Data(base64Encoded: deckString) else {
            logger.error("Can not decode \(deckString)")
            return nil
        }
        
        let deck = Deck()

        let bytes = [UInt8](data)

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
        guard let format = try? FormatType(rawValue: Int(read().toInt64())) else {
            logger.error("cannot get format")
            return nil
        }
        deck.format = format

        // Num Heroes - always 1
        _ = try? read()

        guard let heroId = try? read() else {
            logger.error("Can not get heroId")
            return nil
        }
        deck.heroDbfId = Int(heroId.toInt64())

        var cards: [Card] = []
        func addCard(dbfId: Varint? = nil, count: Int = 1) {
            let dbfId = dbfId ?? (try? read())
            guard let id = dbfId,
                let card = Cards.by(dbfId: Int(id.toInt64())) else {
                logger.error("Can not get card id for deck string: \(deckString)")
                Influx.sendSingleEvent(eventName: "DeckSerializer_failed_addCard", withProperties: ["deckString": deckString])
                return
            }
            logger.verbose("**** got card \(card.id) * \(count)")

            card.count = count
            cards.append(card)
        }

        let numSingleCards = Int((try? read())?.toUInt64() ?? 0)
        logger.verbose("numSingleCards : \(numSingleCards)")
        for _ in 0..<numSingleCards {
            addCard()
        }

        let numDoubleCards = Int((try? read())?.toUInt64() ?? 0)
        logger.verbose("numDoubleCards : \(numDoubleCards)")
        for _ in 0..<numDoubleCards {
            addCard(count: 2)
        }

        let numMultiCards = Int((try? read())?.toUInt64() ?? 0)
        logger.verbose("numMultiCards : \(numMultiCards)")
        for _ in 0..<numMultiCards {
            let dbfId = try? read()
            let count = Int((try? read())?.toInt64() ?? 1)
            addCard(dbfId: dbfId, count: count)
        }

        return deck
    }
    
    static func serialize(deck: Deck, includeComments: Bool) -> String? {
        guard let deckString = serialize(deck: deck) else {
            return nil
        }
        if !includeComments {
            return deckString
        }
        let hero = "\(deck.getHero()?.playerClass ?? .invalid)".capitalized
        var sb = "### \(deck.name.isEmpty ? hero + " Deck" : deck.name)\n"
        sb.append("# Class: \(hero)\n")
        sb.append("# Format: \("\(deck.format)".substring(from: 3).capitalized)\n")
        sb.append("#\n")
        for card in deck.cards.sortCardList() {
            sb.append("# \(card.count)x (\(card.cost) \(card.name)")
            // TODO: sideboards
        }
        sb.append("#\n")
        sb.append("\(deckString)\n")
        sb.append("#\n")
        sb.append("# To use this deck, copy it to your clipboard and create a new deck in Hearthstone\n")
        return sb
    }

    static func serialize(deck: Deck?) -> String? {
        guard let deck else {
            logger.debug("Deck can not be null")
            return nil
        }
        guard deck.heroDbfId != 0 else {
            logger.debug("HeroDbfId can not be zero")
            return nil
        }
        guard deck.getHero()?.type == .hero else {
            logger.debug("HeroDbfId does not represent a valid hero")
            return nil
        }
        guard deck.format != .ft_unknown else {
            logger.debug("Format can not be FT_UNKNOWN")
            return nil
        }
        var data = Data()

        func write(value: Int) {
            let varint = Varint(fromValue: Int64(value))
            data.append(contentsOf: varint.backing)
        }

        data.append(contentsOf: [0])
        write(value: 1)
        write(value: deck.format.rawValue)
        write(value: 1)
        write(value: deck.heroDbfId)
        let cards = deck.cards.sorted(by: {
            return $0.dbfId < $1.dbfId
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
        
        // TODO: sideboards

        return data.base64EncodedString()
    }
}
