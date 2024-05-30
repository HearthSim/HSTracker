//
//  BattlegroundsDb.swift
//  HSTracker
//
//  Created by Francisco Moraes on 4/22/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class BattlegroundsDb {
    private var _cardsByTier = [Int: [Race: [Card]]]()
    private var _duosExclusiveCardsByTier = [Int: [Race: [Card]]]()
    private var _spellsByTier = [Int: [Card]]()
    private var _duosExclusiveSpellsByTier = [Int: [Card]]()
    
    var races = Set<Race>()
    
    init() {
        update(RemoteConfig.data?.battlegrounds_tag_overrides)
    }
    
    private func update(_ tagOverrides: [TagOverride]?) {
        let baconCards = Cards.battlegroundsMinions
        if let overrides = tagOverrides {
            for over in overrides {
                if over.tag == GameTag.is_bacon_pool_minion.rawValue, let card = Cards.by(dbfId: over.dbf_id, collectible: false) {
                    if over.value == 0 {
                        baconCards.removeAll(where: { x in x.dbfId == card.dbfId })
                    } else if over.value == 1 {
                        baconCards.append(card)
                    }
                }
            }
        }
        
        races.removeAll()
        // should we iterate over a card's races instead?
        for race in baconCards.compactMap({ x in x.race }) {
            races.insert(race)
        }
        _cardsByTier.removeAll()
        _duosExclusiveCardsByTier.removeAll()
        for card in baconCards.filter({ _ in true }) {
            let tier = card.techLevel
            if card.battlegroundsDuosExclusive {
                if _duosExclusiveCardsByTier[tier] == nil {
                    _duosExclusiveCardsByTier[tier] = [Race: [Card]]()
                }
                for race in getRaces(card) {
                    if _duosExclusiveCardsByTier[tier]?[race] == nil {
                        _duosExclusiveCardsByTier[tier]?[race] = [Card]()
                    }
                    _duosExclusiveCardsByTier[tier]?[race]?.append(card)
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
        _duosExclusiveSpellsByTier.removeAll()
        for card in Cards.battlegroundsSpells.filter({_ in true}) {
            let tier = card.techLevel
            if card.battlegroundsDuosExclusive {
                if _duosExclusiveSpellsByTier[tier] == nil {
                    _duosExclusiveSpellsByTier[tier] = [Card]()
                }
                _duosExclusiveSpellsByTier[tier]?.append(card)
            } else {
                if _spellsByTier[tier] == nil {
                    _spellsByTier[tier] = [Card]()
                }
                _spellsByTier[tier]?.append(card)
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
    
    func getCards(_ tier: Int, _ race: Race, _ includeDuosExclusive: Bool) -> [Card] {
        guard let cardsByRace = _cardsByTier[tier], let cards = cardsByRace[race] else {
            return [Card]()
        }
        var exclusive = [Card]()
        if includeDuosExclusive, let duosCardsByRace = _duosExclusiveCardsByTier[tier], let duosCards = duosCardsByRace[race] {
            exclusive = duosCards
        }
        return cards + exclusive
    }
    
    func getSpells(_ tier: Int, _ includeDuosExclusive: Bool) -> [Card] {
        guard let cards = _spellsByTier[tier] else {
            return [Card]()
        }
        var exclusive = [Card]()
        if includeDuosExclusive, let duosCards = _duosExclusiveSpellsByTier[tier] {
            exclusive = duosCards
        }
        return cards + exclusive
    }
}
