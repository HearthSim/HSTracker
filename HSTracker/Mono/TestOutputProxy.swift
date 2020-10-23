//
//  TestOutputProxy.swift
//  HSTracker
//
//  Created by Francisco Moraes on 8/18/20.
//  Copyright © 2020 Benjamin Michotte. All rights reserved.
//

import Foundation

class TestOutputProxy: MonoHandle {
    static var _class: OpaquePointer?
    static var _winRate: OpaquePointer!
    static var _lossRate: OpaquePointer!
    static var _tieRate: OpaquePointer!
    static var _myDeathRate: OpaquePointer!
    static var _theirDeathRate: OpaquePointer!
    static var _simulationCount: OpaquePointer!
    static var _myExitCondition: OpaquePointer!
    static var _result: OpaquePointer!
    
    // keeping this here for now, may move to a separate class later
    static var _fightTraceClass: OpaquePointer!
    static var _fightTraceDamage: OpaquePointer!

    override init(obj: UnsafeMutablePointer<MonoObject>?) {
        super.init(obj: obj)
        
        if TestOutputProxy._class == nil {
            TestOutputProxy._class = MonoHelper.loadClass(ns: "BobsBuddy.Simulation", name: "TestOutput")
            TestOutputProxy._winRate = mono_class_get_field_from_name(TestOutputProxy._class, "winRate")
            TestOutputProxy._lossRate = mono_class_get_field_from_name(TestOutputProxy._class, "lossRate")
            TestOutputProxy._tieRate = mono_class_get_field_from_name(TestOutputProxy._class, "tieRate")
            TestOutputProxy._myDeathRate = mono_class_get_field_from_name(TestOutputProxy._class, "myDeathRate")
            TestOutputProxy._theirDeathRate = mono_class_get_field_from_name(TestOutputProxy._class, "theirDeathRate")
            TestOutputProxy._simulationCount = mono_class_get_field_from_name(TestOutputProxy._class, "simulationCount")
            TestOutputProxy._myExitCondition = mono_class_get_field_from_name(TestOutputProxy._class, "myExitCondition")
            TestOutputProxy._result = mono_class_get_field_from_name(TestOutputProxy._class, "result")
            
            TestOutputProxy._fightTraceClass = MonoHelper.loadClass(ns: "BobsBuddy", name: "FightTrace")
            TestOutputProxy._fightTraceDamage = mono_class_get_field_from_name(TestOutputProxy._fightTraceClass, "damage")
        }
    }
    
    func getWinRate() -> Float {
        return MonoHelper.getFloatField(obj: self, field: TestOutputProxy._winRate)
    }

    func getLossRate() -> Float {
        return MonoHelper.getFloatField(obj: self, field: TestOutputProxy._lossRate)
    }

    func getTieRate() -> Float {
        return MonoHelper.getFloatField(obj: self, field: TestOutputProxy._tieRate)
    }
    
    func getMyDeathRate() -> Float {
        return MonoHelper.getFloatField(obj: self, field: TestOutputProxy._myDeathRate)
    }

    func getTheirDeathRate() -> Float {
        return MonoHelper.getFloatField(obj: self, field: TestOutputProxy._theirDeathRate)
    }
    
    func getSimulationCount() -> Int32 {
        return MonoHelper.getIntField(obj: self, field: TestOutputProxy._simulationCount)
    }
    
    func getMyExitCondition() -> Int32 {
        return MonoHelper.getIntField(obj: self, field: TestOutputProxy._myExitCondition)
    }
    
    func getResultDamage() -> [Int32] {
        let field = TestOutputProxy._result

        let res = MonoHelper.getField(obj: self, field: field)
        
        let meth = mono_class_get_method_from_name(mono_object_get_class(res.get()), "ToArray", 0)

        let tempObj = mono_runtime_invoke(meth, res.get(), nil, nil)
        
        let opaque = OpaquePointer(tempObj)
        
        let len = mono_array_length(opaque)

        var arr: [Int32] = []
        
        for i in 0...len-1 {
            let addr = mono_array_addr_with_size(opaque, 8, i)
            
            addr?.withMemoryRebound(to: UnsafeMutablePointer<MonoObject>.self, capacity: 1, {
                let damage = MonoHelper.getIntField(inst: $0.pointee, field: TestOutputProxy._fightTraceDamage)
                arr.append(damage)
            })
        }
        return arr
    }
}
