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

    private(set) var _class = ""
    private(set) var cardId = ""
    private(set) var taunt = false
    private(set) var charge = false
    private(set) var windfury = false
    private(set) var cardType = ""
    
    private(set) var name = ""
    private(set) var attack = 0
    private(set) var health = 0
    private(set) var include = false
    
    private(set) var attacksThisTurn = 0
    private(set) var exhausted = false
    
    private(set) var zone = ""
    
    init(entity: Entity, active: Bool = true) {
        let card = Cards.by(cardId: entity.cardId)
        let cardName = card != nil ? card!.name : ""
        name = String.isNullOrEmpty(entity.name) ? cardName : entity.name!
        
        _stdAttack = entity[.atk]
        _class = entity[.class]
        _health = entity[.health]
        _armor = entity[.armor]
        _durability = entity[.durability]
        _damageTaken = entity[.damage]
        exhausted = entity[.exhausted] == 1
        _cantAttack = entity[.cant_attack] == 1
        _frozen = entity[.frozen] == 1
        charge = entity[.charge] == 1
        windfury = entity[.windfury] == 1
        attacksThisTurn = entity[.num_attacks_this_turn]
        
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
        // V-07-TR-0N is a special case Mega-Windfury
        if !String.isNullOrEmpty(cardId) && cardId == "GVG_111t" {
            return V07TRONAttack(active: active)
        }
        
        // for weapons check for windfury and number of hits left
        if isWeapon {
            if windfury && health >= 2 && attacksThisTurn == 0 {
                return _stdAttack * 2
            }
        }
            // for minions with windfury that haven't already attacked, double attack
        else if windfury && (!active || attacksThisTurn == 0) {
            return _stdAttack * 2
        }
        return _stdAttack
    }
    
    private func isAbleToAttack(active: Bool, isWeapon: Bool) -> Bool {
        // TODO: if frozen on turn, may be able to attack next turn
        // don't include weapons if an active turn, count Hero instead
        if _cantAttack || _frozen || (isWeapon && active) {
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
        // sometimes cards seem to be in wrong zone while in play,
        // these cards don't become exhausted, so check attacks.
        if zone.lowercased() == "deck" || zone.lowercased() == "hand" {
            return (!windfury || attacksThisTurn < 2) && (windfury || attacksThisTurn < 1)
        }
        return true
    }
    
    private func V07TRONAttack(active: Bool) -> Int {
        guard active else {
            return _stdAttack * 4
        }
    
        switch attacksThisTurn {
        case 0: return _stdAttack * 4
        case 1: return _stdAttack * 3
        case 2: return _stdAttack * 2
        default: return _stdAttack
        }
    }
}
