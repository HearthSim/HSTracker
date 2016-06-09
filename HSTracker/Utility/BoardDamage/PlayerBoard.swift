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
    
    var damage: Int {
        return cards.filter { $0.include }
            .map { $0.attack }
            .reduce(0, combine: +)
    }
    
    init(list: [Entity], activeTurn: Bool) {
        cards = []
        let filtered = filter(list)
        let weapon = getWeapon(filtered)
        
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
        return weapons.count == 1 ? weapons.first :
            list.first { $0.hasTag(.JUST_PLAYED) && $0.getTag(.JUST_PLAYED) == 1 }
    }
    
    private func filter(cards: [Entity]) -> [Entity] {
        return cards.filter({ card in
            return card.getTag(.CARDTYPE) != CardType.ENCHANTMENT.rawValue
                && card.getTag(.CARDTYPE) != CardType.HERO_POWER.rawValue
                && card.getTag(.ZONE) != Zone.SETASIDE.rawValue
                && card.getTag(.ZONE) != Zone.GRAVEYARD.rawValue
        })
    }
}