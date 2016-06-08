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
    return "\(NSUUID().UUIDString)-\(NSDate().timeIntervalSince1970)"
}

final class Deck: Unboxable, WrapCustomizable, Hashable, CustomStringConvertible {
    var deckId: String = generateId()
    var name: String?
    var playerClass: String
    var version: String = "1.0"
    var creationDate: NSDate?
    var hearthstatsId: Int?
    var hearthstatsVersionId: Int?
    var isActive: Bool = true
    var isArena: Bool = false
    private var _cards = [Card]()
    private var cards: [Card]?
    var statistics = [Statistic]()

    init(unboxer: Unboxer) {
        self.deckId = unboxer.unbox("deckId")
        self.name = unboxer.unbox("name")
        self.playerClass = unboxer.unbox("playerClass")
        self.version = unboxer.unbox("version")

        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "YYYY-MM-dd HH:mm:ss"
        self.creationDate = unboxer.unbox("creationDate", formatter: dateFormatter)
        if self.creationDate == nil {
            // support old version
            self.creationDate = NSDate(timeIntervalSince1970: unboxer.unbox("creationDate"))
        }
        self.hearthstatsId = unboxer.unbox("hearthstatsId")
        self.hearthstatsVersionId = unboxer.unbox("hearthstatsVersionId")
        self.isActive = unboxer.unbox("isActive")
        self.isArena = unboxer.unbox("isArena")

        let tmpCards: [String: Int] = unboxer.unbox("cards")
        for (cardId, count) in tmpCards {
            if let card = Cards.byId(cardId) {
                card.count = count
                _cards.append(card)
            }
        }

        self.statistics = unboxer.unbox("statistics")
    }

    init(playerClass: String, name: String? = nil, deckId: String? = nil) {
        if let deckId = deckId {
            self.deckId = deckId
        }
        self.name = name
        self.playerClass = playerClass
    }

    func addCard(card: Card) {
        if let _card = _cards.firstWhere({ $0.id == card.id }) {
            _card.count += 1
        } else {
            if card.count == 0 {
                card.count = 1
            }
            _cards.append(card)
        }
        reset()
    }

    func removeAllCards() {
        _cards = [Card]()
    }

    func removeCard(card: Card) {
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
                if let card = Cards.byId(deckCard.id) {
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
        return _cards.map({ $0.count }).reduce(0, combine: +)
    }

    func isValid() -> Bool {
        let count = countCards()
        return count == 30
    }

    var description: String {
        return "<\(NSStringFromClass(self.dynamicType)): "
            + "deckId=\(self.deckId)"
            + ", name=\(self.name)"
            + ", payerClass=\(self.playerClass)"
            + ", self.cards=\(self._cards.toDict())"
            + ">"
    }

    var hashValue: Int {
        return deckId.hashValue
    }

    func wrap() -> AnyObject? {
        reset()
        do {
            var wrapped = try Wrapper().wrap(self)
            wrapped["cards"] = sortedCards.toDict()
            return wrapped
        } catch {
            return nil
        }
    }

    func keyForWrappingPropertyNamed(propertyName: String) -> String? {
        if propertyName == "_cards" {
            return nil
        }

        return propertyName
    }

    func addStatistic(statistic: Statistic) {
        statistics.append(statistic)
    }

    func displayStats() -> String {
        let totalGames = statistics.count
        if totalGames == 0 {
            return "0 - 0"
        }

        return "\(wins()) - \(totalGames - wins()) (\(winPercentage())%)"
    }
    
    func wins() -> Int {
        return statistics.filter { $0.gameResult == .Win }.count
    }
    
    func losses() -> Int {
        return statistics.filter { $0.gameResult == .Loss }.count
    }
    
    func winPercentage() -> Int {
        let totalGames = statistics.count
        if totalGames == 0 {
            return 0
        }
        return Int(round(Double(wins()) / Double(totalGames) * 100))
    }

    func standardViable() -> Bool {
        return !isArena && !_cards.any({ Database.wildSets.contains($0.set) })
    }
}
func == (lhs: Deck, rhs: Deck) -> Bool {
    return lhs.deckId == rhs.deckId && lhs.version == rhs.version
}
