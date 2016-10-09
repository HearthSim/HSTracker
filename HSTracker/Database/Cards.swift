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
        return [.DRUID, .HUNTER, .MAGE, .PALADIN, .PRIEST,
            .ROGUE, .SHAMAN, .WARLOCK, .WARRIOR]
            .sort { NSLocalizedString($0.rawValue.lowercaseString, comment: "")
                < NSLocalizedString($1.rawValue.lowercaseString, comment: "") }
    }()
    
    static var cards = [Card]()

    static func hero(byId cardId: String) -> Card? {
        if let card = cards.firstWhere({ $0.id == cardId && $0.type == .HERO }) {
            return card.copy()
        }
        return nil
    }

    static func isHero(cardId: String?) -> Bool {
        guard !String.isNullOrEmpty(cardId) else { return false }

        return hero(byId: cardId!) != .None
    }

    static func byId(cardId: String?) -> Card? {
        guard !String.isNullOrEmpty(cardId) else { return nil }

        if let card = cards.filter({
            $0.type != .HERO && $0.type != .HERO_POWER
        }).firstWhere({ $0.id == cardId }) {
            return card.copy()
        }
        return nil
    }

    static func any(byId cardId: String) -> Card? {
        if String.isNullOrEmpty(cardId) { return nil }
        if let card = cards.firstWhere({ $0.id == cardId }) {
            return card.copy()
        }
        return nil
    }
    
    static func hero(byPlayerClass name: CardClass) -> Card? {
        switch name {
        case .DRUID: return hero(byId: CardIds.Collectible.Druid.MalfurionStormrage)
        case .HUNTER: return hero(byId: CardIds.Collectible.Hunter.Rexxar)
        case .MAGE: return hero(byId: CardIds.Collectible.Mage.JainaProudmoore)
        case .PALADIN: return hero(byId: CardIds.Collectible.Paladin.UtherLightbringer)
        case .PRIEST: return hero(byId: CardIds.Collectible.Priest.AnduinWrynn)
        case .ROGUE: return hero(byId: CardIds.Collectible.Rogue.ValeeraSanguinar)
        case .SHAMAN: return hero(byId: CardIds.Collectible.Shaman.Thrall)
        case .WARLOCK: return hero(byId: CardIds.Collectible.Warlock.Guldan)
        case .WARRIOR: return hero(byId: CardIds.Collectible.Warrior.GarroshHellscream)
        default: return nil
        }
    }

    static func by(name name: String) -> Card? {
        if let card = collectible().firstWhere({ $0.name == name }) {
            return card.copy()
        }
        return nil
    }

    static func by(englishName name: String) -> Card? {
        if let card = collectible().firstWhere({ $0.enName == name || $0.name == name }) {
            return card.copy()
        }
        return nil
    }
    
    static func by(englishNameCaseInsensitive name: String) -> Card? {
        if let card = collectible().firstWhere({
            $0.enName.caseInsensitiveCompare(name) == NSComparisonResult.OrderedSame ||
                $0.name.caseInsensitiveCompare(name) == NSComparisonResult.OrderedSame
        }) {
            return card.copy()
        }
        return nil
    }

    static func collectible() -> [Card] {
        return cards.filter { $0.collectible && $0.type != .HERO && $0.type != .HERO_POWER }
    }

    static func search(className className: CardClass?, sets: [CardSet] = [],
                                 term: String = "", cost: Int = -1,
                                 rarity: Rarity? = .None, standardOnly: Bool = false,
                                 damage: Int = -1, health: Int = -1, type: CardType = .INVALID,
                                 race: Race?) -> [Card] {
        var cards = collectible()

        if term.isEmpty {
            cards = cards.filter { $0.playerClass == className }
        } else {
            cards = cards.filter { $0.playerClass == className || $0.playerClass == .NEUTRAL }
                .filter {
                    $0.name.lowercaseString.contains(term.lowercaseString) ||
                        $0.enName.lowercaseString.contains(term.lowercaseString) ||
                        $0.text.lowercaseString.contains(term.lowercaseString) ||
                        $0.rarity.rawValue.contains(term.lowercaseString) ||
                        $0.type.rawString().lowercaseString.contains(term.lowercaseString) ||
                        $0.race.rawValue.lowercaseString.contains(term.lowercaseString)
            }
        }

        if type != .INVALID {
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
