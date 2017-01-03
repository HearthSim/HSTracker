//
//  Deck.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 19/02/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import CleanroomLogger
import RealmSwift

func generateId() -> String {
    return "\(UUID().uuidString)-\(Date().timeIntervalSince1970)"
}

class Deck: Object {
    dynamic var deckId: String = generateId()
    dynamic var name = ""

    private dynamic var _playerClass = CardClass.neutral.rawValue
    var playerClass: CardClass {
        get { return CardClass(rawValue: _playerClass)! }
        set { _playerClass = newValue.rawValue }
    }

    dynamic var version = "1.0"
    dynamic var creationDate = Date()
    let hearthstatsId = RealmOptional<Int>()
    let hearthstatsVersionId = RealmOptional<Int>()
    let hearthStatsArenaId = RealmOptional<Int>()
    dynamic var isActive = true
    dynamic var isArena = false

    let hsDeckId = RealmOptional<Int64>()

    let cards = List<RealmCard>()
    let statistics = List<Statistic>()

    override static func primaryKey() -> String? {
        return "deckId"
    }

    func add(card: Card) {
        if card.count == 0 {
            card.count = 1
        }

        if let _card = cards.filter("id = '\(card.id)'").first {
            _card.count += card.count
        } else {
            cards.append(RealmCard(id: card.id, count: card.count))
        }
    }

    func remove(card: Card) {
        if let _card = cards.filter("id = '\(card.id)'").first {
            _card.count -= 1
            if _card.count <= 0 {
                if let index = cards.index(of: _card) {
                    cards.remove(objectAtIndex: index)
                }
            }
        }

        reset()
    }

    private var _cacheCards: [Card]?
    var sortedCards: [Card] {
        if let cards = _cacheCards {
            return cards
        }

        var cache: [Card] = []
        for deckCard in cards {
            if let card = Cards.by(cardId: deckCard.id) {
                card.count = deckCard.count
                cache.append(card)
            }
        }
        cache = cache.sortCardList()
        _cacheCards = cache
        return cache
    }

    func reset() {
        _cacheCards = nil
    }

    func countCards() -> Int {
        return sortedCards.countCards()
    }

    func isValid() -> Bool {
        let count = countCards()
        return count == 30
    }

    func arenaFinished() -> Bool {
        if !isArena { return false }

        var win = 0
        var loss = 0
        for stat in statistics {
            if stat.gameResult == .loss {
                loss += 1
            } else if stat.gameResult == .win {
                win += 1
            }
        }
        return win == 12 || loss == 3
    }

    func standardViable() -> Bool {
        return !isArena && !sortedCards.any {
            $0.set != nil && CardSet.wildSets().contains($0.set!)
        }
    }
}
