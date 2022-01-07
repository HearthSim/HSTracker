//
//  TestInputProxy.swift
//  HSTracker
//
//  Created by Francisco Moraes on 8/11/20.
//  Copyright © 2020 Benjamin Michotte. All rights reserved.
//

import Foundation

class TestInputProxy: MonoHandle {
    static var _class: OpaquePointer?
    static var _constructor: OpaquePointer!
    static var _setHealths: OpaquePointer!
    static var _setTiers: OpaquePointer!
    static var _setPowerID: OpaquePointer!
    static var _setHeroPower: OpaquePointer!
    static var _setTurn: OpaquePointer!
    static var _addSecretFromDbfid: OpaquePointer!
    static var _unitTest: OpaquePointer!
    static var _addMinionToPlayerSide: OpaquePointer!
    static var _addMinionToOpponentSide: OpaquePointer!
    static var _playerLast: OpaquePointer!
    static var _opponentLast: OpaquePointer!
    static var _addMinionToPlayerSideAH: OpaquePointer!
    static var _addMinionToOpponentSideAH: OpaquePointer!
    static var _setPlayerHandSize: OpaquePointer!

    static var _playerSide: OpaquePointer!
    static var _opponentSide: OpaquePointer!
    static var _damageCap: OpaquePointer!
    static var _playerSecrets: OpaquePointer!
    static var _opponentSecrets: OpaquePointer!
    static var _heroPowerInfo: OpaquePointer!
    
    init(simulator: SimulatorProxy) {
        super.init()
        
        if TestInputProxy._class == nil {
            TestInputProxy._class = MonoHelper.loadClass(ns: "BobsBuddy.Simulation", name: "TestInput")
            TestInputProxy._constructor = MonoHelper.getMethod(TestInputProxy._class, ".ctor", 1)
            TestInputProxy._setHealths = MonoHelper.getMethod(TestInputProxy._class, "SetHealths", 2)
            TestInputProxy._setTiers = MonoHelper.getMethod(TestInputProxy._class, "SetTiers", 2)
            TestInputProxy._setPowerID = MonoHelper.getMethod(TestInputProxy._class, "SetPowerID", 2)
            TestInputProxy._setHeroPower = MonoHelper.getMethod(TestInputProxy._class, "SetHeroPower", 2)
            TestInputProxy._setTurn = MonoHelper.getMethod(TestInputProxy._class, "SetTurn", 1)
            TestInputProxy._addSecretFromDbfid = MonoHelper.getMethod(TestInputProxy._class, "AddSecretFromDbfid", 2)
            TestInputProxy._addMinionToPlayerSide = MonoHelper.getMethod(TestInputProxy._class, "AddMinionToPlayerSide", 1)
            TestInputProxy._addMinionToOpponentSide = MonoHelper.getMethod(TestInputProxy._class, "AddMinionToOpponentSide", 1)
            TestInputProxy._playerLast = MonoHelper.getMethod(TestInputProxy._class, "PlayerLast", 0)
            TestInputProxy._opponentLast = MonoHelper.getMethod(TestInputProxy._class, "OpponentLast", 0)
            TestInputProxy._addMinionToPlayerSideAH = MonoHelper.getMethod(TestInputProxy._class, "AddMinionToPlayerSide", 3)
            TestInputProxy._addMinionToOpponentSideAH = MonoHelper.getMethod(TestInputProxy._class, "AddMinionToOpponentSide", 3)
            TestInputProxy._setPlayerHandSize = MonoHelper.getMethod(TestInputProxy._class, "SetPlayerHandSize", 1)

            TestInputProxy._unitTest = MonoHelper.getMethod(TestInputProxy._class, "UnitTestCopyableVersion", 0)
            
            TestInputProxy._playerSide = MonoHelper.getField(TestInputProxy._class, "playerSide")
            TestInputProxy._opponentSide = MonoHelper.getField(TestInputProxy._class, "opponentSide")
            TestInputProxy._damageCap = MonoHelper.getField(TestInputProxy._class, "DamageCap")
            TestInputProxy._playerSecrets = MonoHelper.getField(TestInputProxy._class, "PlayerSecrets")
            TestInputProxy._opponentSecrets = MonoHelper.getField(TestInputProxy._class, "OpponentSecrets")
            TestInputProxy._heroPowerInfo = MonoHelper.getField(TestInputProxy._class, "heroPowerInfo")
        }
        
        let obj = MonoHelper.objectNew(clazz: TestInputProxy._class!)
        set(obj: obj)
        
        let inst = self.get()
        
        let simInst = simulator.get()
        
        let params = UnsafeMutablePointer<UnsafeMutableRawPointer?>.allocate(capacity: 1)
        params[0] = UnsafeMutableRawPointer(simInst)
        
        mono_runtime_invoke(TestInputProxy._constructor, inst, params, nil)
        
        params.deallocate()
    }
    
    func setHealths(player: Int32, opponent: Int32) {
        MonoHelper.setIntInt(obj: self, method: TestInputProxy._setHealths, v1: player, v2: opponent)
    }
    
    func setTiers(player: Int32, opponent: Int32) {
        MonoHelper.setIntInt(obj: self, method: TestInputProxy._setTiers, v1: player, v2: opponent)
    }

    func setPowerID(player: String, opponent: String) {
        MonoHelper.setStringString(obj: self, method: TestInputProxy._setPowerID, v1: player, v2: opponent)
    }

    func setHeroPower(player: Bool, opponent: Bool) {
        MonoHelper.setBoolBool(obj: self, method: TestInputProxy._setHeroPower, v1: player, v2: opponent)
    }
    
    func setDamageCap(value: Int32) {
        MonoHelper.setIntField(obj: self, field: TestInputProxy._damageCap, value: value)
    }
    
    func setTurn(value: Int32) {
        MonoHelper.setInt(obj: self, method: TestInputProxy._setTurn, value: value)
    }
    
    func setPlayerHandSize(value: Int32) {
        MonoHelper.setInt(obj: self, method: TestInputProxy._setPlayerHandSize, value: value)
    }
    
    func getPlayerSide() -> MonoHandle {
        return MonoHelper.getField(obj: self, field: TestInputProxy._playerSide)
    }

    func getOpponentSide() -> MonoHandle {
        return MonoHelper.getField(obj: self, field: TestInputProxy._opponentSide)
    }
    
    func getPlayerSecrets() -> MonoHandle {
        return MonoHelper.getField(obj: self, field: TestInputProxy._playerSecrets)
    }

    func getOpponentSecrets() -> MonoHandle {
        return MonoHelper.getField(obj: self, field: TestInputProxy._opponentSecrets)
    }

    func addAvailableRaces(races: [Race]) {
        let field = mono_class_get_field_from_name(TestInputProxy._class, "availableRaces")
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
        MonoHelper.setIntMonoHandle(obj: self, method: TestInputProxy._addSecretFromDbfid, v1: id, v2: target)
    }
    
    func addMinionToPlayerSide(minion: String) -> MinionProxy {
        return MinionProxy(obj: MonoHelper.invokeString(obj: self, method: TestInputProxy._addMinionToPlayerSide, str: minion))
    }

    func addMinionToOpponentSide(minion: String) -> MinionProxy {
        return MinionProxy(obj: MonoHelper.invokeString(obj: self, method: TestInputProxy._addMinionToOpponentSide, str: minion))
    }
    
    func addMinionToPlayerSide(minion: String, a: Int32, h: Int32) -> MinionProxy {
        return MinionProxy(obj: MonoHelper.invokeStringIntInt(obj: self, method: TestInputProxy._addMinionToPlayerSideAH, str: minion, a: a, b: h))
    }

    func addMinionToOpponentSide(minion: String, a: Int32, h: Int32) -> MinionProxy {
        return MinionProxy(obj: MonoHelper.invokeStringIntInt(obj: self, method: TestInputProxy._addMinionToOpponentSide, str: minion, a: a, b: h))
    }

    func playerLast() -> MinionProxy {
        return MinionProxy(obj: MonoHelper.invoke(obj: self, method: TestInputProxy._playerLast))
    }
    
    func opponentLast() -> MinionProxy {
        return MinionProxy(obj: MonoHelper.invoke(obj: self, method: TestInputProxy._opponentLast))
    }
    func heroPowerInfo() -> HeroPowerInfoProxy {
        let r = mono_field_get_value_object(MonoHelper._monoInstance, TestInputProxy._heroPowerInfo, get())

        return HeroPowerInfoProxy(obj: r)
    }

    func unitestCopyableVersion() -> String {
        let inst = self.get()

        let temp = MonoHandle(obj: mono_runtime_invoke(TestInputProxy._unitTest, inst, nil, nil))

        return MonoHelper.toString(obj: temp)
    }
}
