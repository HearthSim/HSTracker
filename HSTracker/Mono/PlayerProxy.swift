//
//  PlayerProxy.swift
//  HSTracker
//
//  Created by Francisco Moraes on 5/17/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class PlayerProxy: MonoHandle, MonoClassInitializer {
    static var _class: OpaquePointer?
    static var _constructor: OpaquePointer!
    static var _setHealths: OpaquePointer!
    static var _setTiers: OpaquePointer!
    static var _setTurn: OpaquePointer!
    static var _addSecretFromDbfid: OpaquePointer!
    static var _unitTest: OpaquePointer!
    static var _setPlayerHeroPower: OpaquePointer!
    static var _setOpponentHeroPower: OpaquePointer!
    static var _playerQuests: OpaquePointer!
    static var _opponentQuests: OpaquePointer!
    static var _playerDamageTaken: OpaquePointer!
    static var _opponentDamageTaken: OpaquePointer!
    static var _nullableClass: OpaquePointer!
    
    static var _members = [String: OpaquePointer]()
    
    static func initialize() {
        if PlayerProxy._class == nil {
            PlayerProxy._class = MonoHelper.loadClass(ns: "BobsBuddy.Simulation", name: "Player")
            // methods
            PlayerProxy._constructor = MonoHelper.getMethod(PlayerProxy._class, ".ctor", 1)
            PlayerProxy._setPlayerHeroPower = MonoHelper.getMethod(PlayerProxy._class, "SetHeroPower", 5)
            
            // fields
            initializeProperties(properties: [ "Side", "HeroPower", "Quests", "Objectives", "Trinkets", "Secrets", "Hand", "EternalKnightCounter", "UndeadAttackBonus", "ElementalPlayCounter", "BloodGemAtkBuff", "BloodGemHealthBuff", "TavernSpellCounter", "WonLastCombat", "BattlecriesPlayed", "Health", "DamageTaken", "Tier" ])
        }
    }
    
    required init(obj: UnsafeMutablePointer<MonoObject>?) {
        super.init(obj: obj)
    }
    
    init(input: InputProxy?) {
        super.init()
        
        let obj = MonoHelper.objectNew(clazz: PlayerProxy._class!)
        set(obj: obj)
        
        let inst = self.get()
        
        let params = UnsafeMutablePointer<UnsafeMutableRawPointer?>.allocate(capacity: 1)
        if let input {
            params[0] = UnsafeMutableRawPointer(input.get())
        } else {
            params[0] = nil
        }
        _ = mono_runtime_invoke(PlayerProxy._constructor, inst, params, nil)
        
        params.deallocate()

    }
    
    func setHeroPower(heroPowerCardId: String, friendly: Bool, isActivated: Bool, data: Int32, data2: Int32) {
        MonoHelper.setStringBoolBoolIntInt(obj: self, method: PlayerProxy._setPlayerHeroPower, v1: heroPowerCardId, v2: friendly, v3: isActivated, v4: data, v5: data2)
    }
    
    @MonoHandleProperty(property: "Side", owner: PlayerProxy.self)
    var side: MonoHandle
    
    @MonoHandleProperty(property: "HeroPower", owner: PlayerProxy.self)
    var heroPower: HeroPowerDataProxy
    
    @MonoHandleProperty(property: "Quests", owner: PlayerProxy.self)
    var quests: MonoHandle
    
    @MonoHandleProperty(property: "Trinkets", owner: PlayerProxy.self)
    var trinkets: MonoHandle

    @MonoHandleProperty(property: "Objectives", owner: PlayerProxy.self)
    var objectives: MonoHandle
    
    @MonoHandleProperty(property: "Secrets", owner: PlayerProxy.self)
    var secrets: MonoHandle
    
    @MonoHandleProperty(property: "Hand", owner: PlayerProxy.self)
    var hand: MonoHandle
    
    @MonoPrimitiveProperty(property: "EternalKnightCounter", owner: PlayerProxy.self)
    var eternalKnightCounter: Int32
    
    @MonoPrimitiveProperty(property: "UndeadAttackBonus", owner: PlayerProxy.self)
    var undeadAttackBonus: Int32
    
    @MonoPrimitiveProperty(property: "ElementalPlayCounter", owner: PlayerProxy.self)
    var elementalPlayCounter: Int32
    
    @MonoPrimitiveProperty(property: "BloodGemAtkBuff", owner: PlayerProxy.self)
    var bloodGemAtkBuff: Int32
    
    @MonoPrimitiveProperty(property: "BloodGemHealthBuff", owner: PlayerProxy.self)
    var bloodGemHealthBuff: Int32
    
    @MonoPrimitiveProperty(property: "TavernSpellCounter", owner: PlayerProxy.self)
    var tavernSpellCounter: Int32
    
    @MonoPrimitiveProperty(property: "WonLastCombat", owner: PlayerProxy.self)
    var wonLastCombat: Bool
    
    @MonoPrimitiveProperty(property: "BattlecriesPlayed", owner: PlayerProxy.self)
    var battlecriesPlayed: Int32
    
    @MonoPrimitiveProperty(property: "Health", owner: PlayerProxy.self)
    var health: Int32
    
    @MonoPrimitiveProperty(property: "DamageTaken", owner: PlayerProxy.self)
    var damageTaken: Int32
    
    @MonoPrimitiveProperty(property: "Tier", owner: PlayerProxy.self)
    var tier: Int32
}
