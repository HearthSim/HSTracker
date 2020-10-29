//
//  Cards.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 24/05/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation

final class Cards {
    
    static let classes: [CardClass] = {
        return [.druid, .hunter, .mage, .paladin, .priest,
                .rogue, .shaman, .warlock, .warrior, .demonhunter]
            .sorted { NSLocalizedString($0.rawValue, comment: "")
                < NSLocalizedString($1.rawValue, comment: "") }
    }()
    
    static var cards = [Card]()
    // map used to quickly find cards by id
    static var cardsById = [String: Card]()

    static func hero(byId cardId: String) -> Card? {
        if let card = cardsById[cardId] {
            if card.type == .hero {
                return card.copy() as? Card
            }
        }
        return nil
    }

    static func isHero(cardId: String?) -> Bool {
        guard !cardId.isBlank else { return false }

        return hero(byId: cardId!) != .none
    }
    
    static func isPlayableHero(cardId: String?) -> Bool {
        guard !cardId.isBlank else {
            return false
        }
        
        if let card = cardsById[cardId!] {
            if card.type == .hero && card.set != CardSet.core && card.set != CardSet.hero_skins {
                return true
            }
        }
        return false
    }

    static func by(cardId: String?) -> Card? {
        guard !cardId.isBlank else { return nil }

        if let card = cardsById[cardId!] {
            if card.type != .hero_power && (card.type != .hero || (card.type == .hero &&
                                                                    card.set != CardSet.core && card.set != CardSet.hero_skins)) {
                return card.copy() as? Card
            }
        }
        return nil
    }

    static func by(dbfId: Int?, collectible: Bool = true) -> Card? {
        guard let dbfId = dbfId else { return nil }

        if let card = (collectible ? self.collectible() : cards)
            .first(where: { $0.dbfId == dbfId }) {
            return card.copy() as? Card
        }
        return nil
    }

    static func any(byId cardId: String) -> Card? {
        guard !cardId.isBlank else { return nil }

        if let card = cardsById[cardId] {
            return card.copy() as? Card
        }
        return nil
    }
    
    static func hero(byPlayerClass name: CardClass) -> Card? {
        switch name {
        case .druid: return hero(byId: CardIds.Collectible.Druid.MalfurionStormrage)
        case .hunter: return hero(byId: CardIds.Collectible.Hunter.Rexxar)
        case .mage: return hero(byId: CardIds.Collectible.Mage.JainaProudmoore)
        case .paladin: return hero(byId: CardIds.Collectible.Paladin.UtherLightbringer)
        case .priest: return hero(byId: CardIds.Collectible.Priest.AnduinWrynn)
        case .rogue: return hero(byId: CardIds.Collectible.Rogue.ValeeraSanguinar)
        case .shaman: return hero(byId: CardIds.Collectible.Shaman.Thrall)
        case .warlock: return hero(byId: CardIds.Collectible.Warlock.Guldan)
        case .warrior: return hero(byId: CardIds.Collectible.Warrior.GarroshHellscream)
        default: return nil
        }
    }

    static func by(name: String) -> Card? {
        if let card = collectible().first(where: { $0.name == name }) {
            return card.copy() as? Card
        }
        return nil
    }

    static func by(englishName name: String) -> Card? {
        if let card = collectible().first(where: { $0.enName == name || $0.name == name }) {
            return card.copy() as? Card
        }
        return nil
    }
    
    static func by(englishNameCaseInsensitive name: String) -> Card? {
        if let card = collectible().first(where: {
            $0.enName.caseInsensitiveCompare(name) == ComparisonResult.orderedSame ||
                $0.name.caseInsensitiveCompare(name) == ComparisonResult.orderedSame
        }) {
            return card.copy() as? Card
        }
        return nil
    }

    static func collectible() -> [Card] {
        return cards.filter {
            $0.collectible && $0.type != .hero_power &&
            ($0.type != .hero || ($0.type == .hero && $0.set != CardSet.core && $0.set != CardSet.hero_skins ))
                || $0.set == CardSet.wild_event
        }
    }
    
    static func indexOf(id: String) -> Int {
        var low = 0
        var high = cards.count - 1

        while low <= high {
            let mid = (low + high)/2
            let midVal = cards[mid]

            if midVal.id < id {
                 low = mid + 1
            } else if midVal.id > id {
                 high = mid - 1
            } else {
                 return mid
            }
         }
        
         return -(low + 1)
    }

    static func search(className: CardClass?, sets: [CardSet] = [],
                       term: String = "", cost: Int = -1,
                       rarity: Rarity? = .none, standardOnly: Bool = false,
                       damage: Int = -1, health: Int = -1, type: CardType = .invalid,
                       race: Race?) -> [Card] {
        var cards = collectible()

        if term.isEmpty {
            cards = cards.filter { $0.isClass(cardClass: className ?? .neutral) }
        } else {
            cards = cards.filter { $0.isClass(cardClass: className ?? .neutral) || $0.playerClass == .neutral && $0.multiClassGroup == .invalid }
                .filter {
                    $0.name.lowercased().contains(term.lowercased()) ||
                        $0.enName.lowercased().contains(term.lowercased()) ||
                        $0.text.lowercased().contains(term.lowercased()) ||
                        $0.rarity.rawValue.contains(term.lowercased()) ||
                        $0.type.rawString().lowercased().contains(term.lowercased()) ||
                        $0.race.rawValue.lowercased().contains(term.lowercased())
            }
        }

        if type != .invalid {
            cards = cards.filter { $0.type == type }
        }

        if let race = race {
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
