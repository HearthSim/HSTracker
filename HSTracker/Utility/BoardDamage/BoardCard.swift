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
        let card = Cards.byId(entity.cardId)
        let cardName = card != nil ? card!.name : ""
        name = String.isNullOrEmpty(entity.name) ? cardName : entity.name!
        
        _stdAttack = entity.getTag(.ATK)
        _health = entity.getTag(.HEALTH)
        _armor = entity.getTag(.ARMOR)
        _durability = entity.getTag(.DURABILITY)
        _damageTaken = entity.getTag(.DAMAGE)
        exhausted = entity.getTag(.EXHAUSTED) == 1
        _cantAttack = entity.getTag(.CANT_ATTACK) == 1
        _frozen = entity.getTag(.FROZEN) == 1
        charge = entity.getTag(.CHARGE) == 1
        windfury = entity.getTag(.WINDFURY) == 1
        attacksThisTurn = entity.getTag(.NUM_ATTACKS_THIS_TURN)
        
        cardId = entity.cardId
        taunt = entity.getTag(.TAUNT) == 1
        if let _zone = Zone(rawValue: entity.getTag(.ZONE)) {
            zone = "\(_zone)"
        }
        if let _cardType = CardType(rawValue: entity.getTag(.CARDTYPE)) {
            cardType = "\(_cardType)"
        }
        
        health = calculateHealth(entity.isWeapon)
        attack = calculateAttack(active, isWeapon: entity.isWeapon)
        include = isAbleToAttack(active, isWeapon: entity.isWeapon)
    }
    
    private func calculateHealth(isWeapon: Bool) -> Int {
        return isWeapon ? _durability - _damageTaken : _health + _armor - _damageTaken
    }
    
    private func calculateAttack(active: Bool, isWeapon: Bool) -> Int {
        // V-07-TR-0N is a special case Mega-Windfury
        if !String.isNullOrEmpty(cardId) && cardId == "GVG_111t" {
            return V07TRONAttack(active)
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
        if zone.lowercaseString == "deck" || zone.lowercaseString == "hand" {
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