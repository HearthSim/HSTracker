//
//  Deck.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 19/02/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation

class Decks {
    private static var _decks: [Deck]?

    private static var savePath: String? {
        if let path = Settings.instance.deckPath {
            return "\(path)/decks.json"
        }
        return nil
    }

    static func byId(id: String) -> Deck? {
        return decks().filter({ $0.deckId == id }).first
    }

    static func decks() -> [Deck] {
        if let _decks = _decks {
            return _decks
        }

        if let jsonFile = savePath {
            DDLogVerbose("json file : \(jsonFile)")
            if let jsonData = NSData(contentsOfFile: jsonFile) {
                do {
                    let decks: [[String: AnyObject]] = try NSJSONSerialization.JSONObjectWithData(jsonData, options: .AllowFragments) as! [[String: AnyObject]]
                    var validDecks = [Deck]()
                    DDLogVerbose("\(decks)")
                    for _deck in decks {
                        if let playerClass = _deck["playerClass"] as? String {
                            let deck = Deck(playerClass: playerClass, name: _deck["name"] as? String, deckId: _deck["deckId"] as? String)
                            if let version = _deck["version"] as? String {
                                deck.version = version
                            }
                            if let hearthstatsId = _deck["hearthstatsId"] as? Int where hearthstatsId != -1 {
                                deck.hearthstatsId = hearthstatsId
                            }
                            if let hearthstatsVersionId = _deck["hearthstatsVersionId"] as? Int where hearthstatsVersionId != -1 {
                                deck.hearthstatsVersionId = hearthstatsVersionId
                            }
                            if let isActive = _deck["isActive"] as? Int {
                                deck.isActive = Bool(isActive)
                            }
                            if let isArena = _deck["isArena"] as? Int {
                                deck.isArena = Bool(isArena)
                            }
                            if let cards = _deck["cards"] as? [[String: Int]] {
                                for card in cards {
                                    for (cardId, count) in card {
                                        if let card = Cards.byId(cardId) {
                                            card.count = count
                                            deck.addCard(card)
                                        }
                                    }
                                }
                            }

                            DDLogVerbose("\(deck)")
                            if deck.isValid() {
                                validDecks.append(deck)
                            }
                        }
                    }

                    _decks = validDecks
                    return validDecks
                } catch {
                    return [Deck]()
                }
            }
        }
        return [Deck]()
    }

    static func add(deck: Deck) {
        // be sure decks are loaded
        let _ = decks()
        if _decks == nil {
            _decks = [Deck]()
        }
        _decks?.append(deck)
        save()
    }

    static func remove(deck: Deck) {
        let _ = decks()
        guard let _ = _decks else { return }
        _decks?.remove(deck)
        save()
    }

    static func save() {
        if let decks = _decks {
            let jsonDecks: [[String: AnyObject]] = decks.map({
                $0.reset()
                return [
                    "deckId": $0.deckId == nil ? "" : $0.deckId!,
                    "name": $0.name == nil ? "" : $0.name!,
                    "playerClass": $0.playerClass,
                    "version": $0.version,
                    "hearthstatsId": $0.hearthstatsId == nil ? -1 : $0.hearthstatsId!,
                    "hearthstatsVersionId": $0.hearthstatsVersionId == nil ? -1 : $0.hearthstatsVersionId!,
                    "isActive": Int($0.isActive),
                    "isArena": Int($0.isArena),
                    "cards": $0.sortedCards.map({ [$0.cardId: $0.count] })
                ]
            })
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
    var deckId: String? = generateId()
    var name: String?
    var playerClass: String
    var version: String = "1.0"
    var hearthstatsId: Int?
    var hearthstatsVersionId: Int?
    var isActive: Bool = true
    var isArena: Bool = false
    private var _cards = [Card]()
    var cards: [Card]?

    init(playerClass: String, name: String? = nil, deckId: String? = nil) {
        if deckId != nil {
            self.deckId = deckId
        }
        self.name = name
        self.playerClass = playerClass
    }

    func addCard(card: Card) {
        _cards.append(card)
    }

    func save() {
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

    func isValid() -> Bool {
        let count = _cards.map({ $0.count }).reduce(0, combine: +)
        DDLogVerbose("Found \(count)")
        return count == 30
    }

    func displayStats() -> String {
        // TODO
        return "12 - 1 / 97%"
    }

    var description: String {
        return "<\(NSStringFromClass(self.dynamicType)): "
            + "deckId=\(self.deckId)"
            + ", name=\(self.name)"
            + ", payerClass=\(self.playerClass)"
            + ", self.cards=\(self._cards.map({[$0.cardId:$0.count]}))"
            + ">"
    }

    var hashValue: Int {
        if let deckId = deckId {
            return deckId.hashValue
        }
        return 0
    }
}
func == (lhs: Deck, rhs: Deck) -> Bool {
    return lhs.deckId == rhs.deckId && lhs.version == rhs.version
}
