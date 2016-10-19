//
//  Deck.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 19/02/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import CleanroomLogger
import Unbox
import Wrap

func generateId() -> String {
    return "\(UUID().uuidString)-\(Date().timeIntervalSince1970)"
}

final class Deck {
    var deckId: String = generateId()
    var name: String?
    var playerClass: CardClass
    var version: String = "1.0"
    var creationDate: Date?
    var hearthstatsId: Int?
    var hearthstatsVersionId: Int?
    var hearthStatsArenaId: Int?
    var isActive: Bool = true
    var isArena: Bool = false
    fileprivate var _cards = [Card]()
    fileprivate var cards: [Card]?
    var statistics = [Statistic]()

    fileprivate init() {
        self.playerClass = .neutral
    }

    init(playerClass: CardClass, name: String? = nil, deckId: String? = nil) {
        if let deckId = deckId {
            self.deckId = deckId
        }
        self.name = name
        self.playerClass = playerClass
    }

    func add(card: Card) {
        if card.count == 0 {
            card.count = 1
        }

        if let _card = _cards.firstWhere({ $0.id == card.id }) {
            _card.count += card.count
        } else {
            _cards.append(card)
        }
        reset()
    }

    func removeAllCards() {
        _cards = [Card]()
    }

    func remove(card: Card) {
        if let _card = _cards.firstWhere({ $0.id == card.id }) {
            _card.count -= 1
            if _card.count <= 0 {
                _cards.remove(_card)
            }
        }

        reset()
    }

    var sortedCards: [Card] {
        if let cards = self.cards {
            return cards
        } else {
            var cards = [Card]()
            for deckCard in _cards {
                if let card = Cards.by(cardId: deckCard.id) {
                    card.count = deckCard.count
                    cards.append(card)
                }
            }
            cards = cards.sortCardList()
            self.cards = cards
            return cards
        }
    }

    func reset() {
        self.cards = nil
    }

    func countCards() -> Int {
        return _cards.map({ $0.count }).reduce(0, +)
    }

    func isValid() -> Bool {
        let count = countCards()
        return count == 30
    }

    func removeAllStatistics() {
        statistics = []
        Decks.instance.update(deck: self)
    }

    func add(statistic: Statistic) {
        statistic.deck = self
        statistics.append(statistic)
    }

    func standardViable() -> Bool {
        return !isArena && !_cards.any({ $0.set != nil && CardSet.wildSets().contains($0.set!) })
    }
}

extension Deck: Hashable {
    var hashValue: Int {
        return deckId.hashValue
    }

    static func == (lhs: Deck, rhs: Deck) -> Bool {
        return lhs.deckId == rhs.deckId && lhs.version == rhs.version
    }
}

extension Deck: CustomStringConvertible {
    var description: String {
        return "<Deck: "
            + "deckId=\(self.deckId)"
            + ", name=\(self.name)"
            + ", payerClass=\(self.playerClass)"
            + ", cards=\(self._cards)"
            + ">"
    }
}

extension Deck: Unboxable {
    convenience init(unboxer: Unboxer) throws {
        self.init()
        self.deckId = try unboxer.unbox(key: "deckId")
        self.name = unboxer.unbox(key: "name")
        do {
            let cardClass: CardClass = try unboxer.unbox(key: "playerClass")
            self.playerClass = cardClass
        } catch {
            let playerClass: String = try unboxer.unbox(key: "playerClass")
            self.playerClass = CardClass(rawValue: playerClass.lowercased()) ?? .neutral
        }
        self.version = try unboxer.unbox(key: "version")

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YYYY-MM-dd HH:mm:ss"
        self.creationDate = unboxer.unbox(key: "creationDate", formatter: dateFormatter)
        if self.creationDate == nil {
            // support old version
            self.creationDate = Date(timeIntervalSince1970: try unboxer.unbox(key: "creationDate"))
        }
        self.hearthstatsId = unboxer.unbox(key: "hearthstatsId")
        self.hearthstatsVersionId = unboxer.unbox(key: "hearthstatsVersionId")
        self.hearthStatsArenaId = unboxer.unbox(key: "hearthStatsArenaId")
        self.isActive = try unboxer.unbox(key: "isActive")
        self.isArena = try unboxer.unbox(key: "isArena")

        let tmpCards: [String: Int] = try unboxer.unbox(key: "cards")
        for (cardId, count) in tmpCards {
            if let card = Cards.by(cardId: cardId) {
                card.count = count
                _cards.append(card)
            }
        }

        self.statistics = try unboxer.unbox(key: "statistics")
        self.statistics.forEach({$0.deck = self})
    }
}

extension Deck: WrapCustomizable {
    func wrap(context: Any?, dateFormatter: DateFormatter?) -> Any? {
        reset()
        do {
            var wrapped: [String: Any] = try Wrapper(context: context, dateFormatter: dateFormatter)
                .wrap(object: self)
            wrapped["cards"] = sortedCards.toDict()

            return wrapped
        } catch {
            return nil
        }
    }

    func keyForWrapping(propertyNamed propertyName: String) -> String? {
        if propertyName == "_cards" {
            return nil
        }

        return propertyName
    }
}
