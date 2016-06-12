//
//  Cards.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 24/05/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation

final class Cards {
    static var cards = [Card]()

    static func heroById(cardId: String) -> Card? {
        if let card = cards.firstWhere({ $0.id == cardId && $0.type == "hero" }) {
            return card.copy()
        }
        return nil
    }

    static func isHero(cardId: String?) -> Bool {
        guard !String.isNullOrEmpty(cardId) else { return false }

        return heroById(cardId!) != .None
    }

    static func byId(cardId: String?) -> Card? {
        guard !String.isNullOrEmpty(cardId) else { return nil }

        if let card = cards.filter({
            $0.type != "hero" && $0.type != "hero power"
        }).firstWhere({ $0.id == cardId }) {
            return card.copy()
        }
        return nil
    }

    static func anyById(cardId: String) -> Card? {
        if let card = cards.firstWhere({ $0.id == cardId }) {
            return card.copy()
        }
        return nil
    }
    
    static func heroByPlayerClass(name: String) -> Card? {
        switch name {
        case "druid": return self.heroById(CardIds.Collectible.Druid.MalfurionStormrage)
        case "hunter": return self.heroById(CardIds.Collectible.Hunter.Rexxar)
        case "mage": return self.heroById(CardIds.Collectible.Mage.JainaProudmoore)
        case "paladin": return self.heroById(CardIds.Collectible.Paladin.UtherLightbringer)
        case "priest": return self.heroById(CardIds.Collectible.Priest.AnduinWrynn)
        case "rogue": return self.heroById(CardIds.Collectible.Rogue.ValeeraSanguinar)
        case "shaman": return self.heroById(CardIds.Collectible.Shaman.Thrall)
        case "warlock": return self.heroById(CardIds.Collectible.Warlock.Guldan)
        case "warrior": return self.heroById(CardIds.Collectible.Warrior.GarroshHellscream)
        default: return nil
        }
    }

    static func byName(name: String) -> Card? {
        if let card = collectible().firstWhere({ $0.name == name }) {
            return card.copy()
        }
        return nil
    }

    static func byEnglishName(name: String) -> Card? {
        if let card = collectible().firstWhere({ $0.enName == name || $0.name == name }) {
            return card.copy()
        }
        return nil
    }

    static func collectible() -> [Card] {
        return cards.filter { $0.collectible && $0.type != "hero" && $0.type != "hero power" }
    }

    static func byClass(className: String?, set: String?) -> [Card] {
        var sets: [CardSet] = []
        if let set = CardSet(rawValue: set ?? "") {
            sets.append(set)
        }
        return byClass(className, sets: sets)
    }

    static func byClass(className: String?, sets: [CardSet]) -> [Card] {
        var _cards = collectible().filter { $0.playerClass == className }
        if !sets.isEmpty {
            _cards = _cards.filter { $0.set != nil && sets.contains($0.set!) }
        }
        return _cards
    }

    static func search(className className: String?, sets: [CardSet] = [],
                                 term: String = "", cost: Int = -1,
                                 rarity: Rarity? = .None, standardOnly: Bool = false,
                                 damage: Int = -1, health: Int = -1, type: String = "",
                                 race: String = "") -> [Card] {
        var cards = collectible()

        if term.isEmpty {
            cards = cards.filter { $0.playerClass == className }
        } else {
            cards = cards.filter { $0.playerClass == className || $0.playerClass == "neutral" }
                .filter {
                    $0.name.lowercaseString.contains(term.lowercaseString) ||
                        $0.enName.lowercaseString.contains(term.lowercaseString) ||
                        $0.text.lowercaseString.contains(term.lowercaseString) ||
                        $0.rarity.rawValue.contains(term.lowercaseString) ||
                        $0.type.lowercaseString.contains(term.lowercaseString) ||
                        $0.race.contains(term.lowercaseString)
            }
        }

        if !type.isEmpty {
            cards = cards.filter { $0.type == type }
        }

        if !race.isEmpty {
            cards = cards.filter { $0.race == race }
        }

        if health != -1 {
            cards = cards.filter { $0.health == health }
        }

        if damage != -1 {
            cards = cards.filter { $0.attack == damage }
        }

        if standardOnly {
            cards = cards.filter { $0.isStandard }
        }

        if let rarity = rarity {
            cards = cards.filter { $0.rarity == rarity }
        }

        if !sets.isEmpty {
            cards = cards.filter { $0.set != nil && sets.contains($0.set!) }
        }

        if cost != -1 {
            cards = cards.filter {
                if cost == 7 {
                    return $0.cost >= 7
                }
                return $0.cost == cost
            }
        }

        return cards.sortCardList()
    }
}
