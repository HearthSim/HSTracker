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

    static var _members = [String: OpaquePointer]()
    
    static func initialize() {
        if OutputProxy._class == nil {
            OutputProxy._class = MonoHelper.loadClass(ns: "BobsBuddy.Simulation", name: "Output")
            initializeFields(fields: ["winRate", "lossRate", "tieRate", "myDeathRate", "theirDeathRate", "simulationCount", "damageResults"])
            OutputProxy._myExitCondition = MonoHelper.getField(OutputProxy._class, "myExitCondition")
        }
    }
    
    required init(obj: UnsafeMutablePointer<MonoObject>?) {
        super.init(obj: obj)
    }
    
    @MonoPrimitiveField(field: "winRate", owner: OutputProxy.self)
    var winRate: Float

    @MonoPrimitiveField(field: "lossRate", owner: OutputProxy.self)
    var lossRate: Float

    @MonoPrimitiveField(field: "tieRate", owner: OutputProxy.self)
    var tieRate: Float
    
    @MonoPrimitiveField(field: "myDeathRate", owner: OutputProxy.self)
    var myDeathRate: Float

    @MonoPrimitiveField(field: "theirDeathRate", owner: OutputProxy.self)
    var theirDeathRate: Float
    
    @MonoPrimitiveField(field: "simulationCount", owner: OutputProxy.self)
    var simulationCount: Int32
    
    @MonoHandleField(field: "damageResults", owner: OutputProxy.self)
    private var _damageResults: MonoHandle

    func getMyExitCondition() -> ExitConditions {
        return ExitConditions(rawValue: Int(MonoHelper.getIntField(obj: self, field: OutputProxy._myExitCondition))) ?? .completedSimulations
    }
    
    func getResultDamage() -> [Int32] {
        let res = _damageResults

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
