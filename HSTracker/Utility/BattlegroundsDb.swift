//
//  BattlegroundsDb.swift
//  HSTracker
//
//  Created by Francisco Moraes on 4/22/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class BattlegroundsDbSingleton {
    static let instance: BattlegroundsDb = {
        let result = BattlegroundsDb.init()
        return result
    }()
}

class BattlegroundsDb {
    private var _cardsByTier = [Int: [Race: [Card]]]()
    private var _solosExclusiveCardsByTier = [Int: [Race: [Card]]]()
    private var _duosExclusiveCardsByTier = [Int: [Race: [Card]]]()
    private var _spellsByTier = [Int: [Card]]()
    private var _solosExclusiveSpellsByTier = [Int: [Card]]()
    private var _duosExclusiveSpellsByTier = [Int: [Card]]()
    private var _buddiesByTier = [Int: [Card]]()
    private var _solosExclusiveBuddiesByTier = [Int: [Card]]()
    private var _duosExclusiveBuddiesByTier = [Int: [Card]]()
    
    var races = Set<Race>()
    
    fileprivate init() {
        update(RemoteConfig.battlegroundsTagOverrides)
    }
    
    private func update(_ tagOverrides: [TagOverride]?) {
        var overrides = [Int: (GameTag, Int)]()
        
        if let tagOverrides {
            for tagOverride in tagOverrides {
                overrides[tagOverride.dbf_id] = (GameTag(rawValue: tagOverride.tag) ?? .ignore_damage, tagOverride.value)
            }
        }
        
        func getTag(_ card: Card, _ tag: GameTag) -> Int {
            if let tagOverride = overrides[card.dbfId] {
                return tagOverride.1
            }
            if tag == .tech_level {
                return card.techLevel
            } else if tag == .is_bacon_pool_minion {
                return card.isBaconPoolMinion ? 1 : 0
            } else if tag == .is_bacon_duos_exclusive {
                return card.isBaconDuosExclusive
            } else if tag == .is_bacon_pool_spell {
                return card.isBaconPoolSpell ? 1 : 0
            } else if tag == .bacon_buddy {
                return card.isBaconBuddy ? 1 : 0
            } else if tag == .bacon_tripled_base_minion_id {
                return card.baconTripledBaseMinionId
            }
            return 0
        }
        
        let baconCards = Cards.cards.filter({ x in getTag(x, .tech_level) > 0 && getTag(x, .is_bacon_pool_minion) > 0})
        
        races.removeAll()
        // should we iterate over a card's races instead?
        for race in baconCards.compactMap({ x in x.race }) {
            races.insert(race)
        }
        _cardsByTier.removeAll()
        _solosExclusiveCardsByTier.removeAll()
        _duosExclusiveCardsByTier.removeAll()
        for card in baconCards {
            let tier = getTag(card, .tech_level)
            let duosExclusive = getTag(card, .is_bacon_duos_exclusive)
            // the game doesn't actually set this ever to a negative value, but we use that as a sentinel
            // value to hide Solos-exclusive cards in Duos
            if duosExclusive > 0 {
                if _duosExclusiveCardsByTier[tier] == nil {
                    _duosExclusiveCardsByTier[tier] = [Race: [Card]]()
                }
                
                for race in getRaces(card) {
                    if _duosExclusiveCardsByTier[tier]?[race] == nil {
                        _duosExclusiveCardsByTier[tier]?[race] = [Card]()
                    }
                    _duosExclusiveCardsByTier[tier]?[race]?.append(card)
                }
            } else if duosExclusive < 0 {
                if _solosExclusiveCardsByTier[tier] == nil {
                    _solosExclusiveCardsByTier[tier] = [Race: [Card]]()
                }
                
                for race in getRaces(card) {
                    if _solosExclusiveCardsByTier[tier]?[race] == nil {
                        _solosExclusiveCardsByTier[tier]?[race] = [Card]()
                    }
                    _solosExclusiveCardsByTier[tier]?[race]?.append(card)
                }
            } else {
                if _cardsByTier[tier] == nil {
                    _cardsByTier[tier] = [Race: [Card]]()
                }
                
                for race in getRaces(card) {
                    if _cardsByTier[tier]?[race] == nil {
                        _cardsByTier[tier]?[race] = [Card]()
                    }
                    _cardsByTier[tier]?[race]?.append(card)
                }
            }
        }
        
        _spellsByTier.removeAll()
        _solosExclusiveSpellsByTier.removeAll()
        _duosExclusiveSpellsByTier.removeAll()
        
        let baconSpells = Cards.cards.filter({ x in getTag(x, .tech_level) > 0 && x.type == .battleground_spell && getTag(x, .is_bacon_pool_spell) > 0})
        for card in baconSpells {
            let tier = getTag(card, .tech_level)
            let duosExclusive = getTag(card, .is_bacon_duos_exclusive)
            
            if duosExclusive > 0 {
                if _duosExclusiveSpellsByTier[tier] == nil {
                    _duosExclusiveSpellsByTier[tier] = [Card]()
                }
                _duosExclusiveSpellsByTier[tier]?.append(card)
            } else if duosExclusive < 0 {
                if _solosExclusiveSpellsByTier[tier] == nil {
                    _solosExclusiveSpellsByTier[tier] = [Card]()
                }
                _solosExclusiveSpellsByTier[tier]?.append(card)
            } else {
                if _spellsByTier[tier] == nil {
                    _spellsByTier[tier] = [Card]()
                }
                _spellsByTier[tier]?.append(card)
            }
        }

        // Buddies, mirroring HDT's _buddies filter: BACON_BUDDY == 1 and no
        // BACON_TRIPLED_BASE_MINION_ID, which drops the golden (tripled) copies
        // and keeps one entry per buddy.
        _buddiesByTier.removeAll()
        _solosExclusiveBuddiesByTier.removeAll()
        _duosExclusiveBuddiesByTier.removeAll()

        let baconBuddies = Cards.cards.filter({ x in getTag(x, .bacon_buddy) == 1 && getTag(x, .bacon_tripled_base_minion_id) == 0 })
        for card in baconBuddies {
            let tier = getTag(card, .tech_level)
            let duosExclusive = getTag(card, .is_bacon_duos_exclusive)

            if duosExclusive > 0 {
                if _duosExclusiveBuddiesByTier[tier] == nil {
                    _duosExclusiveBuddiesByTier[tier] = [Card]()
                }
                _duosExclusiveBuddiesByTier[tier]?.append(card)
            } else if duosExclusive < 0 {
                if _solosExclusiveBuddiesByTier[tier] == nil {
                    _solosExclusiveBuddiesByTier[tier] = [Card]()
                }
                _solosExclusiveBuddiesByTier[tier]?.append(card)
            } else {
                if _buddiesByTier[tier] == nil {
                    _buddiesByTier[tier] = [Card]()
                }
                _buddiesByTier[tier]?.append(card)
            }
        }
    }
    
    private func getRaces(_ card: Card) -> [Race] {
        if card.race == .invalid {
            let racesInText = races.filter { x in x != .all && x != .invalid }.filter { x in
                let raceText = x == .mechanical ? "Mech" : "\(x)".capitalized

                return card.enText.contains(raceText)
            }
            if racesInText.count == 1, let res = racesInText.first {
                return [res]
            }
        }
    
        return card.races.count > 1 ? card.races : [card.race]
    }
    
    func getCards(_ tier: Int, _ race: Race, _ isDuos: Bool) -> [Card] {
        var cards = [Card]()
        if let cardsByRace = _cardsByTier[tier], let defaultCards = cardsByRace[race] {
            cards = defaultCards
        }
        let exclusiveCardsByTier = isDuos ? _duosExclusiveCardsByTier : _solosExclusiveCardsByTier
        var exclusiveCards = [Card]()
        if let exclusiveCardsByRace = exclusiveCardsByTier[tier], let theExclusiveCards = exclusiveCardsByRace[race] {
            exclusiveCards = theExclusiveCards
        }
        return cards + exclusiveCards
    }
    
    func getCardsByRaces(_ races: [Race], _ isDuos: Bool) -> [Card] {
        var cards = [Card]()
        
        for tier in _cardsByTier.values {
            for race in races {
                if let tierCards = tier[race] {
                    cards.append(contentsOf: tierCards)
                }
            }
        }
        
        for tier in isDuos ? _duosExclusiveCardsByTier.values : _solosExclusiveCardsByTier.values {
            for race in races {
                if let exclusiveCards = tier[race] {
                    cards.append(contentsOf: exclusiveCards)
                }
            }
        }
        
        return cards
    }
    
    func getSpells(_ isDuos: Bool) -> [Card] {
        var allSpells = [Card]()
        
        for tierEntry in _spellsByTier {
            allSpells.append(contentsOf: tierEntry.value)
        }
        
        let exclusiveSpellsDict = isDuos ? _duosExclusiveSpellsByTier : _solosExclusiveSpellsByTier
        for tierEntry in exclusiveSpellsDict {
            allSpells.append(contentsOf: tierEntry.value)
        }
        
        return allSpells
    }
    
    func getSpells(_ tier: Int, _ isDuos: Bool) -> [Card] {
        var spells = [Card]()
        if let defaultSpells = _spellsByTier[tier] {
            spells = defaultSpells
        }
        var exclusiveSpells = [Card]()
        if let theExclusiveSpells = (isDuos ? _duosExclusiveSpellsByTier[tier] : _solosExclusiveSpellsByTier[tier]) {
            exclusiveSpells = theExclusiveSpells
        }
        return spells + exclusiveSpells
    }

    // Mirrors HDT's GetCards(tier, keyword, races, isDuos). HDT flattens every
    // tier via GetCardsByRaces and then re-groups by the TECH_LEVEL tag; since
    // the tier is already the index key here, we read the one tier directly.
    // Cards carrying two races appear once per race, so results are deduped by
    // id - HDT's .Distinct().
    func getCards(_ tier: Int, keyword: BattlegroundsKeyword, races: [Race], _ isDuos: Bool) -> [Card] {
        var seen = Set<String>()
        var result = [Card]()
        for race in races {
            for card in getCards(tier, race, isDuos) where keyword.matches(card) {
                if seen.insert(card.id).inserted {
                    result.append(card)
                }
            }
        }
        return result
    }

    // Spells matching a keyword, across every tier - the keyword view shows them
    // as one trailing group rather than per tier.
    //
    // Diverges from HDT's GetSpells(keyword, isDuos) deliberately: that one skips
    // duos-exclusive spells *while in duos* (and solos-exclusive while in solos),
    // inverting the sense every other query in both codebases uses. Reusing
    // getSpells(isDuos) here keeps the mode filtering consistent with the tier and
    // minion-type views.
    func getSpells(keyword: BattlegroundsKeyword, _ isDuos: Bool) -> [Card] {
        return getSpells(isDuos).filter { keyword.matches($0) }
    }

    func getBuddies(_ tier: Int, _ isDuos: Bool) -> [Card] {
        var buddies = [Card]()
        if let defaultBuddies = _buddiesByTier[tier] {
            buddies = defaultBuddies
        }
        var exclusiveBuddies = [Card]()
        if let theExclusiveBuddies = (isDuos ? _duosExclusiveBuddiesByTier[tier] : _solosExclusiveBuddiesByTier[tier]) {
            exclusiveBuddies = theExclusiveBuddies
        }
        return buddies + exclusiveBuddies
    }
}
