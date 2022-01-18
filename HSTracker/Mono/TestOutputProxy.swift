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
    static var _damageResults: OpaquePointer!
    
    override init(obj: UnsafeMutablePointer<MonoObject>?) {
        super.init(obj: obj)
        
        if TestOutputProxy._class == nil {
            TestOutputProxy._class = MonoHelper.loadClass(ns: "BobsBuddy.Simulation", name: "TestOutput")
            TestOutputProxy._winRate = MonoHelper.getField(TestOutputProxy._class, "winRate")
            TestOutputProxy._lossRate = MonoHelper.getField(TestOutputProxy._class, "lossRate")
            TestOutputProxy._tieRate = MonoHelper.getField(TestOutputProxy._class, "tieRate")
            TestOutputProxy._myDeathRate = MonoHelper.getField(TestOutputProxy._class, "myDeathRate")
            TestOutputProxy._theirDeathRate = MonoHelper.getField(TestOutputProxy._class, "theirDeathRate")
            TestOutputProxy._simulationCount = MonoHelper.getField(TestOutputProxy._class, "simulationCount")
            TestOutputProxy._myExitCondition = MonoHelper.getField(TestOutputProxy._class, "myExitCondition")
            TestOutputProxy._damageResults = MonoHelper.getField(TestOutputProxy._class, "damageResults")
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
    
    func getMyExitCondition() -> ExitConditions {
        return ExitConditions(rawValue: Int(MonoHelper.getIntField(obj: self, field: TestOutputProxy._myExitCondition))) ?? .completedSimulations
    }
    
    func getResultDamage() -> [Int32] {
        let field = TestOutputProxy._damageResults

        let res = MonoHelper.getField(obj: self, field: field)
        
        let meth = mono_class_get_method_from_name(mono_object_get_class(res.get()), "ToArray", 0)

        let tempObj = mono_runtime_invoke(meth, res.get(), nil, nil)
        
        let opaque = OpaquePointer(tempObj)
        
        let len = mono_array_length(opaque)

        var arr: [Int32] = []
        
        let addr = mono_array_addr_with_size(opaque, Int32(MemoryLayout<Int32>.size), 0)
        addr?.withMemoryRebound(to: Int32.self, capacity: Int(len), { x in
            for i in 0...len-1 {
                arr.append(x[Int(i)])
            }
        })
        return arr
    }
}
