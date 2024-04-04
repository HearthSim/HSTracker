//
//  Deck.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 19/02/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import RealmSwift
import HearthMirror

func generateId() -> String {
    return "\(UUID().uuidString)-\(Date().timeIntervalSince1970)"
}

class Deck: Object {
    @objc dynamic var deckId: String = generateId()
    @objc dynamic var name = ""

    @objc private dynamic var _playerClass = CardClass.neutral.rawValue
    var playerClass: CardClass {
        get { return CardClass(rawValue: _playerClass)! }
        set { _playerClass = newValue.rawValue }
    }
    @objc dynamic var heroId = ""

    @objc dynamic var deckMajorVersion: Int = 1
    @objc dynamic var deckMinorVersion: Int = 0
    
    @objc dynamic var creationDate = Date()
    @objc dynamic var lastEdited = Date()
    let hearthstatsId = RealmProperty<Int?>()
    let hearthstatsVersionId = RealmProperty<Int?>()
    let hearthStatsArenaId = RealmProperty<Int?>()
    @objc dynamic var isActive = true
    @objc dynamic var isArena = false
    @objc dynamic var isDungeon = false
    @objc dynamic var isDuels = false

    let hsDeckId = RealmProperty<Int64?>()

    let cards = List<RealmCard>()
    let gameStats = List<GameStats>()
    
    var tmpCards = [Card]()
    
    var sideboards = List<RealmSideboard>()

    override static func ignoredProperties() -> [String] {
        return [ "tmpCards" ]
    }
    
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
                    cards.remove(at: index)
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
        return Deck.isExactlyWhizbang(self) || count == 30 || count == 40
    }
    
    static func isExactlyWhizbang(_ deck: Deck) -> Bool {
        return deck.cards.count == 1 && (deck.cards.first?.id == CardIds.Collectible.Neutral.WhizbangTheWonderful || deck.cards.first?.id == CardIds.Collectible.Neutral.SplendiferousWhizbang)
    }
    
    static func isExactlyWhizbang(_ deck: MirrorDeck) -> Bool {
        return deck.cards.count == 1 && (deck.cards.first?.cardId == CardIds.Collectible.Neutral.WhizbangTheWonderful || deck.cards.first?.cardId == CardIds.Collectible.Neutral.SplendiferousWhizbang)
    }

    func arenaFinished() -> Bool {
        if !isArena { return false }

        var win = 0
        var loss = 0
        for stat in gameStats {
            if stat.result == .loss {
                loss += 1
            } else if stat.result == .win {
                win += 1
            }
        }
        return win == 12 || loss == 3
    }
    
    func isDungeonRunCompleted() -> Bool {
        return isDungeon ? gameStats.filter({ x in x.result == .win }).count == 8 ||
        gameStats.filter({ x in x.result == .loss }).count == 1 : false
    }

    func isDuelsRunCompleted() -> Bool {
        return isDuels ? gameStats.filter({ x in x.result == .win }).count == 12 ||
        gameStats.filter({ x in x.result == .loss }).count == 3 : false
    }

    func standardViable() -> Bool {
        return !isArena && !sortedCards.any {
            $0.set != nil && CardSet.wildSets().contains($0.set!)
        }
    }

    var isWildDeck: Bool {
        return sortedCards.any { CardSet.wildSets().contains($0.set ?? .invalid) }
    }
    
    var isClassicDeck: Bool {
        return sortedCards.all { CardSet.classicSets().contains($0.set ?? .invalid) }
    }
    
    var isTwistDeck: Bool {
        return sortedCards.all { CardSet.twistSets().contains($0.set ?? .invalid) && !$0.isNeutral() }
    }
    
    func guessFormatType() -> FormatType {
        if isClassicDeck {
            return .ft_classic
        }
        if isTwistDeck {
            return .ft_twist
        }
        if isWildDeck {
            return .ft_wild
        }
        return .ft_standard
    }
    
    /**
     * Compares the card content to the other deck
     */
    func isContentEqualTo(mirrorDeck: MirrorDeck) -> Bool {
        let mirrorCards = mirrorDeck.cards
        for c in self.cards {
            guard let othercard = mirrorCards.first(where: {$0.cardId == c.id}) else {
                return false
            }
            if c.count != othercard.count.intValue {
                return false
            }
        }
        return true
    }
    
    func diff(newDeck: MirrorDeck) -> [Card] {
        return Deck.diffTo(cards: cards.compactMap { x in Card(fromRealCard: x) }, newCards: newDeck.cards.compactMap { x in Card(fromMirrorCard: x)})
    }

    func sideboardDiff(newDeck: MirrorDeck) -> [Card] {
        let current = Array(sideboards.flatMap { x in x.cards }.compactMap { x in Card(fromRealCard: x) })
        let new = Array(newDeck.sideboards.flatMap { x in x.value }.compactMap { x in Card(fromMirrorCard: x) })
        return Deck.diffTo(cards: current, newCards: new)
    }

    static func diffTo(cards: [Card], newCards: [Card]) -> [Card] {
        var diffs = [Card]()
        
        for c in cards {
            guard let othercard = newCards.first(where: {$0.id == c.id}) else {
                diffs.append(c.copy())
                continue
            }
            if c.count != othercard.count {
                let diffc = c.copy()
                diffc.count = abs(c.count - othercard.count)
                diffs.append(diffc)
            }
        }
        for c in newCards where !cards.any({ x in x.id == c.id }) {
            diffs.append(c)
        }
        return diffs
    }
    
    func incrementVersion(major: Int) {
        self.deckMajorVersion += major
    }
    
    func incrementVersion(minor: Int) {
        self.deckMinorVersion += minor
    }
}

class RealmSideboard: EmbeddedObject {
    @objc dynamic var ownerCardId: String
    let cards = List<RealmCard>()

    override init() {
        ownerCardId = ""
        super.init()
    }

    init(ownerCardId: String) {
        self.ownerCardId = ownerCardId
        super.init()
    }

    func add(card: Card) {
        if card.count == 0 {
            card.count = 1
        }

        self.cards.append(RealmCard(id: card.id, count: card.count))
    }
}
