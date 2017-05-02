//
//  BoardHero.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 9/06/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation

class BoardHero: IBoardEntity {
    private(set) var _baseAttack = 0
    private(set) var _hero: BoardCard
    private(set) var _weapon: BoardCard?

    var name: String { return _hero.name }
    var cardId: String { return _hero.cardId }
    var hasWeapon: Bool { return _weapon != nil }
    
    // total health, including armor
    var health: Int { return _hero.health }
    
    // total attack, weapon plus abilities
    private(set) var attack = 0
    
    var attacksThisTurn: Int { return _hero.attacksThisTurn }
    
    var exhausted: Bool { return _hero.exhausted }
    
    private(set) var include = false
    
    var zone: String { return _hero.zone }
    
    init(hero: Entity, weapon: Entity?, activeTurn: Bool) {
        _hero = BoardCard(entity: hero, active: activeTurn)
        // hero gains windfury with weapon, doubling attack get base attack
        _baseAttack = hero[.atk]
        if let weapon = weapon {
            _weapon = BoardCard(entity: weapon, active: activeTurn)
        }
        include = activeTurn && _hero.include
        attack = attackWithWeapon()
    }
    
    private func attackWithWeapon() -> Int {
        // weapon is equipped
        if let weapon = _weapon, include {
            // windfury weapon, with more than 2 chages
            // and hero hasn't attacked yet this turn.
            // better to check weapon for durability in
            // case of windfury, instead of heros exhausted
            if weapon.windfury && weapon.health >= 2 && _hero.attacksThisTurn == 0 {
                // double the hero attack value
                return _baseAttack * 2
            }
        }

        // otherwise normal hero attack is correct
        return _baseAttack
    }
}
