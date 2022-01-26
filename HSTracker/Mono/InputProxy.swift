//
//  TestInputProxy.swift
//  HSTracker
//
//  Created by Francisco Moraes on 8/11/20.
//  Copyright © 2020 Benjamin Michotte. All rights reserved.
//

import Foundation

class InputProxy: MonoHandle, MonoClassInitializer {
    static var _class: OpaquePointer?
    static var _constructor: OpaquePointer!
    static var _setHealths: OpaquePointer!
    static var _setTiers: OpaquePointer!
    static var _setTurn: OpaquePointer!
    static var _addSecretFromDbfid: OpaquePointer!
    static var _unitTest: OpaquePointer!
    static var _setPlayerHandSize: OpaquePointer!
    static var _setPlayerHeroPower: OpaquePointer!
    static var _setOpponentHeroPower: OpaquePointer!

    static var _playerHeroPower: OpaquePointer!
    static var _opponentHeroPower: OpaquePointer!
    
    static func initialize() {
        if InputProxy._class == nil {
            InputProxy._class = MonoHelper.loadClass(ns: "BobsBuddy.Simulation", name: "Input")
            // methods
            InputProxy._constructor = MonoHelper.getMethod(InputProxy._class, ".ctor", 1)
            InputProxy._setHealths = MonoHelper.getMethod(InputProxy._class, "SetHealths", 2)
            InputProxy._setTiers = MonoHelper.getMethod(InputProxy._class, "SetTiers", 2)
            InputProxy._setTurn = MonoHelper.getMethod(InputProxy._class, "SetTurn", 1)
            InputProxy._addSecretFromDbfid = MonoHelper.getMethod(InputProxy._class, "AddSecretFromDbfid", 2)
            InputProxy._setPlayerHandSize = MonoHelper.getMethod(InputProxy._class, "SetPlayerHandSize", 1)
            InputProxy._unitTest = MonoHelper.getMethod(InputProxy._class, "UnitTestCopyableVersion", 0)
            InputProxy._setPlayerHeroPower = MonoHelper.getMethod(InputProxy._class, "SetPlayerHeroPower", 3)
            InputProxy._setOpponentHeroPower = MonoHelper.getMethod(InputProxy._class, "SetOpponentHeroPower", 3)
            
            // fields
            // these fields crashed when trying to use the property wrapper, so leaving as-is for now
            InputProxy._playerHeroPower = MonoHelper.getField(InputProxy._class, "PlayerHeroPower")
            InputProxy._opponentHeroPower = MonoHelper.getField(InputProxy._class, "OpponentHeroPower")
        }
    }
    
    init(simulator: SimulatorProxy) {
        super.init()
        
        let obj = MonoHelper.objectNew(clazz: InputProxy._class!)
        set(obj: obj)
        
        let inst = self.get()
        
        let simInst = simulator.get()
        
        let params = UnsafeMutablePointer<UnsafeMutableRawPointer?>.allocate(capacity: 1)
        params[0] = UnsafeMutableRawPointer(simInst)
        
        mono_runtime_invoke(InputProxy._constructor, inst, params, nil)
        
        params.deallocate()
    }
    
    required init(obj: UnsafeMutablePointer<MonoObject>?) {
        fatalError("init(obj:) has not been implemented")
    }
    
    func setHealths(player: Int32, opponent: Int32) {
        MonoHelper.setIntInt(obj: self, method: InputProxy._setHealths, v1: player, v2: opponent)
    }
    
    func setTiers(player: Int32, opponent: Int32) {
        MonoHelper.setIntInt(obj: self, method: InputProxy._setTiers, v1: player, v2: opponent)
    }

    func setTurn(value: Int32) {
        MonoHelper.setInt(obj: self, method: InputProxy._setTurn, value: value)
    }
    
    func setPlayerHandSize(value: Int32) {
        MonoHelper.setInt(obj: self, method: InputProxy._setPlayerHandSize, value: value)
    }
    
    func addAvailableRaces(races: [Race]) {
        let field = mono_class_get_field_from_name(InputProxy._class, "availableRaces")
        let inst = get()
        let obj = mono_field_get_value_object(MonoHelper._monoInstance, field, inst)
        
        let clazz = mono_object_get_class(obj)
        let method = mono_class_get_method_from_name(clazz, "Add", 1)
        
        let params = UnsafeMutablePointer<UnsafeMutablePointer<Int>>.allocate(capacity: 1)

        let a = UnsafeMutablePointer<Int>.allocate(capacity: 1)

        for i in 0..<races.count {
            let v = Race.allCases.firstIndex(of: races[i])
            
            a.pointee = v!
            params[0] = a
            
            _ = params.withMemoryRebound(to: UnsafeMutableRawPointer?.self, capacity: 1, {
                mono_runtime_invoke(method, obj, $0, nil)
            })
        }
        a.deallocate()
        params.deallocate()
    }
    
    func addSecretFromDbfid(id: Int32, target: MonoHandle) {
        MonoHelper.setIntMonoHandle(obj: self, method: InputProxy._addSecretFromDbfid, v1: id, v2: target)
    }
    
    func playerHeroPower() -> HeroPowerDataProxy {
        let r = mono_field_get_value_object(MonoHelper._monoInstance, InputProxy._playerHeroPower, get())

        return HeroPowerDataProxy(obj: r)
    }
    
    func opponentHeroPower() -> HeroPowerDataProxy {
        let r = mono_field_get_value_object(MonoHelper._monoInstance, InputProxy._opponentHeroPower, get())

        return HeroPowerDataProxy(obj: r)
    }

    func setPlayerHeroPower(heroPowerCardId: String, isActivated: Bool, data: Int32) {
        let hp = playerHeroPower()
        hp.setCardId(value: heroPowerCardId)
        hp.setIsActivated(value: isActivated)
        hp.setData(value: data)
    }
    
    func setOpponentHeroPower(heroPowerCardId: String, isActivated: Bool, data: Int32) {
        let hp = opponentHeroPower()
        hp.setCardId(value: heroPowerCardId)
        hp.setIsActivated(value: isActivated)
        hp.setData(value: data)
    }

    func unitestCopyableVersion() -> String {
        let inst = self.get()

        let temp = MonoHandle(obj: mono_runtime_invoke(InputProxy._unitTest, inst, nil, nil))

        return MonoHelper.toString(obj: temp)
    }
    
    @MonoHandleField(field: "opponentSide", owner: InputProxy.self)
    var opponentSide: MonoHandle

    @MonoHandleField(field: "playerSide", owner: InputProxy.self)
    var playerSide: MonoHandle
    
    @MonoInt32Field(field: "DamageCap", owner: InputProxy.self)
    var damageCap: Int32

    @MonoHandleField(field: "PlayerSecrets", owner: InputProxy.self)
    var playerSecrets: MonoHandle

    @MonoHandleField(field: "OpponentSecrets", owner: InputProxy.self)
    var opponentSecrets: MonoHandle
    
}
