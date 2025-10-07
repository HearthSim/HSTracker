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
    static var _setSecrets: OpaquePointer!
    static var _setPlayerHeroPower: OpaquePointer!
    
    static var _members = [String: OpaquePointer]()
    
    static func initialize() {
        if PlayerProxy._class == nil {
            PlayerProxy._class = MonoHelper.loadClass(ns: "BobsBuddy.Simulation", name: "Player")
            // methods
            PlayerProxy._constructor = MonoHelper.getMethod(PlayerProxy._class, ".ctor", 1)
            PlayerProxy._setPlayerHeroPower = MonoHelper.getMethod(PlayerProxy._class, "AddHeroPower", 7)
            PlayerProxy._setSecrets = MonoHelper.getMethod(PlayerProxy._class, "SetSecretsHstracker", 1)
            
            // fields
            initializeProperties(properties: [ "Side", "HeroPowers", "Quests", "Objectives", "Trinkets", "Secrets", "Hand", "FriendlyMinionsDeadLastCombatCounter", "EternalKnightCounter", "AncestralAutomatonCounter", "UndeadAttackBonus", "ElementalPlayCounter", "BloodGemAtkBuff", "BloodGemHealthBuff", "TavernSpellCounter", "PiratesSummonCounter", "ResourcesSpentThisGame", "BeastsSummonCounter", "BeetlesAtkBuff", "BeetlesHealthBuff", "BattlecryCounter", "WonLastCombat", "BattlecriesPlayed", "Health", "DamageTaken", "Tier" ])
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
    
    func addHeroPower(heroPowerCardId: String, friendly: Bool, isActivated: Bool, data: Int32, data2: Int32, data3: Int32, attachedMinion: MonoHandle = MonoHandle()) {
        MonoHelper.setStringBoolBoolIntIntIntHandle(obj: self, method: PlayerProxy._setPlayerHeroPower, v1: heroPowerCardId, v2: friendly, v3: isActivated, v4: data, v5: data2, v6: data3, v7: attachedMinion)
    }
    
    func setSecrets(secrets: [Int]) {
        let params = UnsafeMutablePointer<UnsafeMutableRawPointer?>.allocate(capacity: 1)
        
        let arr = mono_array_new(MonoHelper._monoInstance, mono_get_int32_class(), UInt(secrets.count))
        for index in 0 ..< secrets.count {
            let addr = mono_array_addr_with_size(arr, Int32(MemoryLayout<Int32>.size), UInt(index))
            addr?.withMemoryRebound(to: Int32.self, capacity: 1, {
                $0.pointee = Int32(secrets[index])
            })
        }
        
        params[0] = UnsafeMutableRawPointer(arr)

        _ = mono_runtime_invoke(PlayerProxy._setSecrets, self.get(), params, nil)
        
        params.deallocate()
    }
    
    @MonoHandleProperty(property: "Side", owner: PlayerProxy.self)
    var side: MonoHandle
    
    @MonoHandleProperty(property: "HeroPowers", owner: PlayerProxy.self)
    var heroPowers: MonoHandle
    
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
    
    @MonoPrimitiveProperty(property: "FriendlyMinionsDeadLastCombatCounter", owner: PlayerProxy.self)
    var friendlyMinionsDeadLastCombatCounter: Int32
    
    @MonoPrimitiveProperty(property: "EternalKnightCounter", owner: PlayerProxy.self)
    var eternalKnightCounter: Int32
    
    @MonoPrimitiveProperty(property: "AncestralAutomatonCounter", owner: PlayerProxy.self)
    var ancestralAutomatonCounter: Int32

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
    
    @MonoPrimitiveProperty(property: "PiratesSummonCounter", owner: PlayerProxy.self)
    var piratesSummonCounter: Int32
    
    @MonoPrimitiveProperty(property: "ResourcesSpentThisGame", owner: PlayerProxy.self)
    var resourcesSpentThisGame: Int32
    
    @MonoPrimitiveProperty(property: "BeastsSummonCounter", owner: PlayerProxy.self)
    var beastsSummonCounter: Int32

    @MonoPrimitiveProperty(property: "BeetlesAtkBuff", owner: PlayerProxy.self)
    var beetlesAtkBuff: Int32

    @MonoPrimitiveProperty(property: "BattlecryCounter", owner: PlayerProxy.self)
    var battlecryCounter: Int32
    
    @MonoPrimitiveProperty(property: "BeetlesHealthBuff", owner: PlayerProxy.self)
    var beetlesHealthBuff: Int32

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
