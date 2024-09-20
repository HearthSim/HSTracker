//
//  BoardCard.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 9/06/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation

class BoardCard: IBoardEntity {
    private var _armor = 0
    private var _cantAttack = false
    private var _damageTaken = 0
    private var _durability = 0
    private var _frozen = false
    private var _health = 0
    private var _stdAttack = 0
    
    private(set) var cardId = ""
    private(set) var silenced = false
    private(set) var taunt = false
    private(set) var charge = false
    private(set) var windfury = false
    private(set) var megaWindfury = false
    private(set) var cardType = ""
    
    private(set) var name = ""
    private(set) var attack = 0
    private(set) var health = 0
    private(set) var include = false
    
    private(set) var attacksThisTurn = 0
    private var attacksPerTurn: Int {
        if megaWindfury && !silenced {
            return 4
        } else if windfury {
            return 2
        }
        return 1
    }
    private(set) var exhausted = false
    private(set) var dormant = false
    private(set) var titan = false
    private(set) var titanAbilitiesUsed = 0
    
    private(set) var zone = ""
    
    init(entity: Entity, active: Bool = true) {
        let card = Cards.by(cardId: entity.cardId)
        let cardName = card != nil ? card!.name : ""
        name = entity.name.isBlank ? cardName : entity.name!
        
        _stdAttack = entity.has(tag: .hide_stats) ? 0 : entity[.atk]
        _health = entity.has(tag: .hide_stats) ? 0 : entity[.health]
        _armor = entity[.armor]
        _durability = entity[.durability]
        _damageTaken = entity[.damage]
        exhausted = entity[.exhausted] == 1 || (entity[.num_turns_in_play] == 0 && !entity.isHero)
        _cantAttack = entity[.cant_attack] == 1
        _frozen = entity[.frozen] == 1
        silenced = entity[.silenced] == 1
        charge = entity[.charge] == 1
        windfury = entity[.windfury] == 1
        megaWindfury = entity[.mega_windfury] == 1 || entity[.windfury] == 3
        attacksThisTurn = entity[.num_attacks_this_turn]
        dormant = entity[.dormant] == 1
        titan = entity[.titan] == 1
        if titan {
            if entity[.titan_ability_used_1] == 1 {
                titanAbilitiesUsed += 1
            }
            if entity[.titan_ability_used_2] == 1 {
                titanAbilitiesUsed += 1
            }
            if entity[.titan_ability_used_3] == 1 {
                titanAbilitiesUsed += 1
            }
        }
        
        cardId = entity.cardId
        taunt = entity[.taunt] == 1
        if let _zone = Zone(rawValue: entity[.zone]) {
            zone = "\(_zone)"
        }
        if let _cardType = CardType(rawValue: entity[.cardtype]) {
            cardType = "\(_cardType)"
        }
        
        health = calculateHealth(isWeapon: entity.isWeapon)
        attack = calculateAttack(active: active, isWeapon: entity.isWeapon)
        include = isAbleToAttack(active: active, isWeapon: entity.isWeapon)
    }
    
    private func calculateHealth(isWeapon: Bool) -> Int {
        return isWeapon ? _durability - _damageTaken : _health + _armor - _damageTaken
    }
    
    private func calculateAttack(active: Bool, isWeapon: Bool) -> Int {
        var remainingAttacks = max(attacksPerTurn - (active ? attacksThisTurn : 0), 0)
        
        if isWeapon {
            // for weapons, clamp remaining attacks to health
            remainingAttacks = min(remainingAttacks, health)
        }
        return remainingAttacks * _stdAttack
    }
    
    private func isAbleToAttack(active: Bool, isWeapon: Bool) -> Bool {
        // TODO: if frozen on turn, may be able to attack next turn
        // don't include weapons if an active turn, count Hero instead
        if _cantAttack || _frozen || (isWeapon && active) || dormant || (titan && titanAbilitiesUsed < 3) {
            return false
        }
        if !active {
            // include everything that can attack if not an active turn
            return true
        }
        if exhausted {
            // newly played card could be given charge
            return charge && attacksThisTurn == 0
        }
        if attacksThisTurn == attacksPerTurn {
            return false
        }
        // sometimes cards seem to be in wrong zone while in play,
        // these cards don't become exhausted, so check attacks.
        if zone.lowercased() == "deck" || zone.lowercased() == "hand" {
            return (!windfury || attacksThisTurn < 2) && (windfury || attacksThisTurn < 1)
        }
        return true
    }
}
