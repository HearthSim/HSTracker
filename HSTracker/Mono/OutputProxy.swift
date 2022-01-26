//
//  TestOutputProxy.swift
//  HSTracker
//
//  Created by Francisco Moraes on 8/18/20.
//  Copyright © 2020 Benjamin Michotte. All rights reserved.
//

import Foundation

class OutputProxy: MonoHandle, MonoClassInitializer {
    static var _class: OpaquePointer?
    static var _winRate: OpaquePointer!
    static var _lossRate: OpaquePointer!
    static var _tieRate: OpaquePointer!
    static var _myDeathRate: OpaquePointer!
    static var _theirDeathRate: OpaquePointer!
    static var _simulationCount: OpaquePointer!
    static var _myExitCondition: OpaquePointer!
    static var _damageResults: OpaquePointer!

    static func initialize() {
        if OutputProxy._class == nil {
            OutputProxy._class = MonoHelper.loadClass(ns: "BobsBuddy.Simulation", name: "Output")
            OutputProxy._winRate = MonoHelper.getField(OutputProxy._class, "winRate")
            OutputProxy._lossRate = MonoHelper.getField(OutputProxy._class, "lossRate")
            OutputProxy._tieRate = MonoHelper.getField(OutputProxy._class, "tieRate")
            OutputProxy._myDeathRate = MonoHelper.getField(OutputProxy._class, "myDeathRate")
            OutputProxy._theirDeathRate = MonoHelper.getField(OutputProxy._class, "theirDeathRate")
            OutputProxy._simulationCount = MonoHelper.getField(OutputProxy._class, "simulationCount")
            OutputProxy._myExitCondition = MonoHelper.getField(OutputProxy._class, "myExitCondition")
            OutputProxy._damageResults = MonoHelper.getField(OutputProxy._class, "damageResults")
        }
    }
    
    required init(obj: UnsafeMutablePointer<MonoObject>?) {
        super.init(obj: obj)
    }
    
    func getWinRate() -> Float {
        return MonoHelper.getFloatField(obj: self, field: OutputProxy._winRate)
    }

    func getLossRate() -> Float {
        return MonoHelper.getFloatField(obj: self, field: OutputProxy._lossRate)
    }

    func getTieRate() -> Float {
        return MonoHelper.getFloatField(obj: self, field: OutputProxy._tieRate)
    }
    
    func getMyDeathRate() -> Float {
        return MonoHelper.getFloatField(obj: self, field: OutputProxy._myDeathRate)
    }

    func getTheirDeathRate() -> Float {
        return MonoHelper.getFloatField(obj: self, field: OutputProxy._theirDeathRate)
    }
    
    func getSimulationCount() -> Int32 {
        return MonoHelper.getIntField(obj: self, field: OutputProxy._simulationCount)
    }
    
    func getMyExitCondition() -> ExitConditions {
        return ExitConditions(rawValue: Int(MonoHelper.getIntField(obj: self, field: OutputProxy._myExitCondition))) ?? .completedSimulations
    }
    
    func getResultDamage() -> [Int32] {
        let field = OutputProxy._damageResults

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
