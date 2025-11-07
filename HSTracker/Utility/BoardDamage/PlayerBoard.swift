//
//  PlayerBoard.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 9/06/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation

class PlayerBoard {
    private(set) var cards: [IBoardEntity]
    private(set) var hero: BoardHero?
    private(set) var heroPower: HeroPower?
    
    var damage: Int {
        return cards.filter { $0.include && !$0.dormant}
            .map { $0.attack }
            .reduce(0, +)
    }
    
    var hasInfiniteDamage: Bool {
        return cards.filter { x in x.include }.any { x in x.hasInfiniteAttack }
    }
    
    init(list: [Entity], activeTurn: Bool) {
        cards = []
        let filtered = filter(cards: list)
        let weapon = getWeapon(list: filtered)
        if let heroPowerEntity = list.filter({$0[.cardtype] == CardType.hero_power.rawValue}).last {
            self.heroPower = HeroPower(entity: heroPowerEntity)
        }

        for card in filtered {
            if card.isHero {
                hero = BoardHero(hero: card, weapon: weapon, activeTurn: activeTurn)
                cards.append(hero!)
            } else {
                cards.append(BoardCard(entity: card, active: activeTurn))
            }
        }
    }
    
    func getWeapon(list: [Entity]) -> Entity? {
        let weapons = list.filter { $0.isWeapon }
        if weapons.count == 0 {
            return nil
        }
        
        if weapons.count == 1 {
            return weapons[0]
        }
        
        return list.first { $0.has(tag: .just_played) && $0[.just_played] == 1 }
    }
    
    private func filter(cards: [Entity]) -> [Entity] {
        return cards.filter({ card in
            return card[.cardtype] != CardType.player.rawValue
                && card[.cardtype] != CardType.enchantment.rawValue
                && card[.cardtype] != CardType.hero_power.rawValue
                && card[.zone] != Zone.setaside.rawValue
                && card[.zone] != Zone.graveyard.rawValue
        })
    }
}
