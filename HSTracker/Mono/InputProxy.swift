//
//  TestInputProxy.swift
//  HSTracker
//
//  Created by Francisco Moraes on 8/11/20.
//  Copyright © 2020 Benjamin Michotte. All rights reserved.
//

import Foundation

class InputProxy: MonoHandle {
    static var _class: OpaquePointer?
    static var _constructor: OpaquePointer!
    static var _setHealths: OpaquePointer!
    static var _setTiers: OpaquePointer!
    static var _setPowerID: OpaquePointer!
    static var _setHeroPower: OpaquePointer!
    static var _setTurn: OpaquePointer!
    static var _addSecretFromDbfid: OpaquePointer!
    static var _unitTest: OpaquePointer!
    static var _playerLast: OpaquePointer!
    static var _opponentLast: OpaquePointer!
    static var _setPlayerHandSize: OpaquePointer!
    static var _opponentPowerId: OpaquePointer!

    static var _playerSide: OpaquePointer!
    static var _opponentSide: OpaquePointer!
    static var _damageCap: OpaquePointer!
    static var _playerSecrets: OpaquePointer!
    static var _opponentSecrets: OpaquePointer!
    static var _heroPowerInfo: OpaquePointer!
    
    init(simulator: SimulatorProxy) {
        super.init()
        
        if InputProxy._class == nil {
            InputProxy._class = MonoHelper.loadClass(ns: "BobsBuddy.Simulation", name: "Input")
            // methods
            InputProxy._constructor = MonoHelper.getMethod(InputProxy._class, ".ctor", 1)
            InputProxy._setHealths = MonoHelper.getMethod(InputProxy._class, "SetHealths", 2)
            InputProxy._setTiers = MonoHelper.getMethod(InputProxy._class, "SetTiers", 2)
            InputProxy._setPowerID = MonoHelper.getMethod(InputProxy._class, "SetPowerID", 2)
            InputProxy._setHeroPower = MonoHelper.getMethod(InputProxy._class, "SetHeroPower", 2)
            InputProxy._setTurn = MonoHelper.getMethod(InputProxy._class, "SetTurn", 1)
            InputProxy._addSecretFromDbfid = MonoHelper.getMethod(InputProxy._class, "AddSecretFromDbfid", 2)
            InputProxy._setPlayerHandSize = MonoHelper.getMethod(InputProxy._class, "SetPlayerHandSize", 1)
            InputProxy._unitTest = MonoHelper.getMethod(InputProxy._class, "UnitTestCopyableVersion", 0)
            
            // fields
            InputProxy._playerSide = MonoHelper.getField(InputProxy._class, "playerSide")
            InputProxy._opponentSide = MonoHelper.getField(InputProxy._class, "opponentSide")
            InputProxy._damageCap = MonoHelper.getField(InputProxy._class, "DamageCap")
            InputProxy._playerSecrets = MonoHelper.getField(InputProxy._class, "PlayerSecrets")
            InputProxy._opponentSecrets = MonoHelper.getField(InputProxy._class, "OpponentSecrets")
            InputProxy._heroPowerInfo = MonoHelper.getField(InputProxy._class, "heroPowerInfo")
            InputProxy._opponentPowerId = MonoHelper.getField(InputProxy._class, "opponentPowerID")
        }
        
        let obj = MonoHelper.objectNew(clazz: InputProxy._class!)
        set(obj: obj)
        
        let inst = self.get()
        
        let simInst = simulator.get()
        
        let params = UnsafeMutablePointer<UnsafeMutableRawPointer?>.allocate(capacity: 1)
        params[0] = UnsafeMutableRawPointer(simInst)
        
        mono_runtime_invoke(InputProxy._constructor, inst, params, nil)
        
        params.deallocate()
    }
    
    func setHealths(player: Int32, opponent: Int32) {
        MonoHelper.setIntInt(obj: self, method: InputProxy._setHealths, v1: player, v2: opponent)
    }
    
    func setTiers(player: Int32, opponent: Int32) {
        MonoHelper.setIntInt(obj: self, method: InputProxy._setTiers, v1: player, v2: opponent)
    }

    func setPowerID(player: String, opponent: String) {
        MonoHelper.setStringString(obj: self, method: InputProxy._setPowerID, v1: player, v2: opponent)
    }

    func setHeroPower(player: Bool, opponent: Bool) {
        MonoHelper.setBoolBool(obj: self, method: InputProxy._setHeroPower, v1: player, v2: opponent)
    }
    
    func setDamageCap(value: Int32) {
        MonoHelper.setIntField(obj: self, field: InputProxy._damageCap, value: value)
    }
    
    func setTurn(value: Int32) {
        MonoHelper.setInt(obj: self, method: InputProxy._setTurn, value: value)
    }
    
    func setPlayerHandSize(value: Int32) {
        MonoHelper.setInt(obj: self, method: InputProxy._setPlayerHandSize, value: value)
    }
    
    func getPlayerSide() -> MonoHandle {
        return MonoHelper.getField(obj: self, field: InputProxy._playerSide)
    }

    func getOpponentSide() -> MonoHandle {
        return MonoHelper.getField(obj: self, field: InputProxy._opponentSide)
    }
    
    func getPlayerSecrets() -> MonoHandle {
        return MonoHelper.getField(obj: self, field: InputProxy._playerSecrets)
    }

    func getOpponentSecrets() -> MonoHandle {
        return MonoHelper.getField(obj: self, field: InputProxy._opponentSecrets)
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
    
    func playerLast() -> MinionProxy {
        return MinionProxy(obj: MonoHelper.invoke(obj: self, method: InputProxy._playerLast))
    }
    
    func opponentLast() -> MinionProxy {
        return MinionProxy(obj: MonoHelper.invoke(obj: self, method: InputProxy._opponentLast))
    }
    func heroPowerInfo() -> HeroPowerInfoProxy {
        let r = mono_field_get_value_object(MonoHelper._monoInstance, InputProxy._heroPowerInfo, get())

        return HeroPowerInfoProxy(obj: r)
    }
    
    func opponentPowerId() -> String {
        return MonoHelper.getStringField(obj: self, field: InputProxy._opponentPowerId)
    }

    func unitestCopyableVersion() -> String {
        let inst = self.get()

        let temp = MonoHandle(obj: mono_runtime_invoke(InputProxy._unitTest, inst, nil, nil))

        return MonoHelper.toString(obj: temp)
    }
}
