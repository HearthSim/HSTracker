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
}
