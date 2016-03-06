//
//  Deck.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 19/02/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation

class Decks {
    private static var _decks: [String: Deck]?

    private static var savePath: String? {
        if let path = Settings.instance.deckPath {
            return "\(path)/decks.json"
        }
        return nil
    }

    static func byId(id: String) -> Deck? {
        return decks().filter({ $0.deckId == id }).first
    }

    private static func loadJsonDecks() -> [String: [String: AnyObject]] {
        if let jsonFile = savePath,
            let jsonData = NSData(contentsOfFile: jsonFile) {
                DDLogVerbose("json file : \(jsonFile)")
                do {
                    let decks: [String: [String: AnyObject]] = try NSJSONSerialization.JSONObjectWithData(jsonData, options: .AllowFragments) as! [String: [String: AnyObject]]
                    return decks
                } catch {
                }
        }
        return [String: [String: AnyObject]]()
    }

    static func resetDeck(deck: Deck) {
        let decks = loadJsonDecks()
        if let jsonDeck = decks[deck.deckId],
            let _deck = Deck.fromDict(jsonDeck) where _deck.isValid() {
                _decks![_deck.deckId] = _deck
        }
    }

    static func decks() -> [Deck] {
        if let _decks = _decks {
            return _decks.map { $0.1 }
        }

        let decks = loadJsonDecks()
        var validDecks = [String: Deck]()
        for (_, _deck) in decks {
            if let deck = Deck.fromDict(_deck) where deck.isValid() {
                validDecks[deck.deckId] = deck
            }
        }

        _decks = validDecks
        return validDecks.map { $0.1 }
    }

    static func add(deck: Deck) {
        // be sure decks are loaded
        let _ = decks()
        if _decks == nil {
            _decks = [String: Deck]()
        }
        if let _ = _decks {
            self._decks![deck.deckId] = deck
        }
        save()
    }

    static func remove(deck: Deck) {
        let _ = decks()
        guard let _ = _decks else { return }
        if let _ = _decks {
            self._decks![deck.deckId] = nil
        }
        save()
    }

    static func save() {
        if let decks = _decks {
            var jsonDecks = [String: [String: AnyObject]]()
            for (deckId, deck) in decks {
                jsonDecks[deckId] = deck.toDict()
            }
            if let jsonFile = savePath {
                do {
                    let data = try NSJSONSerialization.dataWithJSONObject(jsonDecks, options: .PrettyPrinted)
                    data.writeToFile(jsonFile, atomically: true)
                }
                catch {
                    // TODO error
                }
            }
        }
    }
}

func generateId() -> String {
    return "\(NSUUID().UUIDString)-\(NSDate().timeIntervalSince1970)"
}

class Deck : Hashable, CustomStringConvertible {
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
    var cards: [Card]?
    var statistics = [Statistic]()

    init(playerClass: String, name: String? = nil, deckId: String? = nil) {
        if let deckId = deckId {
            self.deckId = deckId
        }
        self.name = name
        self.playerClass = playerClass
    }

    func addCard(card: Card) {
        if let _card = _cards.firstWhere({ $0.cardId == card.cardId }) {
            _card.count += 1
        }
        else {
            if card.count == 0 {
                card.count = 1
            }
            _cards.append(card)
        }
        reset()
    }

    func removeCard(card: Card) {
        if let _card = _cards.firstWhere({ $0.cardId == card.cardId }) {
            _card.count -= 1
            if _card.count <= 0 {
                _cards.remove(_card)
            }
        }

        reset()
    }

    func save() {
        creationDate = NSDate()
        Decks.add(self)
    }

    var sortedCards: [Card] {
        if let cards = self.cards {
            return cards
        }
        else {
            var cards = [Card]()
            for deckCard in _cards {
                if let card = Cards.byId(deckCard.cardId) {
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
        DDLogVerbose("Found \(count)")
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

    func toDict() -> [String: AnyObject] {
        self.reset()
        return [
            "deckId": deckId,
            "name": name == nil ? "" : name!,
            "playerClass": playerClass,
            "version": version,
            "hearthstatsId": (hearthstatsId == nil ? -1 : hearthstatsId!),
            "hearthstatsVersionId": (hearthstatsVersionId == nil ? -1 : hearthstatsVersionId!),
            "isActive": Int(isActive),
            "isArena": Int(isArena),
            "cards": sortedCards.toDict(),
            "creationDate": (creationDate == nil ? -1 : creationDate!.timeIntervalSince1970),
            "statistics": statistics.toDict()
        ]
    }

    static func fromDict(dict: [String: AnyObject]) -> Deck? {
        guard let _ = dict["playerClass"] else { return nil }

        let playerClass = dict["playerClass"] as! String
        let deck = Deck(playerClass: playerClass,
            name: dict["name"] as? String,
            deckId: dict["deckId"] as? String)

        if let version = dict["version"] as? String {
            deck.version = version
        }
        if let hearthstatsId = dict["hearthstatsId"] as? Int where hearthstatsId != -1 {
            deck.hearthstatsId = hearthstatsId
        }
        if let hearthstatsVersionId = dict["hearthstatsVersionId"] as? Int where hearthstatsVersionId != -1 {
            deck.hearthstatsVersionId = hearthstatsVersionId
        }
        if let isActive = dict["isActive"] as? Int {
            deck.isActive = Bool(isActive)
        }
        if let isArena = dict["isArena"] as? Int {
            deck.isArena = Bool(isArena)
        }
        if let creationDate = dict["creationDate"] as? Double {
            deck.creationDate = NSDate(timeIntervalSince1970: creationDate)
        }
        if let cards = dict["cards"] as? [String: Int] {
            for (cardId, count) in cards {
                if let card = Cards.byId(cardId) {
                    card.count = count
                    deck.addCard(card)
                }
            }
        }
        if let statistics = dict["statistics"] as? [[String: AnyObject]] {
            for stat in statistics {
                if let statistic = Statistic.fromDict(stat) {
                    deck.addStatistic(statistic)
                }
            }
        }

        DDLogVerbose("\(deck)")
        return deck
    }

    func addStatistic(statistic: Statistic) {
        statistics.append(statistic)
    }

    func displayStats() -> String {
        let totalGames = statistics.count
        if totalGames == 0 {
            return "0 - 0"
        }
        let wins = statistics.filter { $0.gameResult == .Win }.count

        return "\(wins) - \(totalGames - wins) / \(wins / totalGames * 100)%"
    }
}
func == (lhs: Deck, rhs: Deck) -> Bool {
    return lhs.deckId == rhs.deckId && lhs.version == rhs.version
}
