//
//  TestInputProxy.swift
//  HSTracker
//
//  Created by Francisco Moraes on 8/11/20.
//  Copyright © 2020 Benjamin Michotte. All rights reserved.
//

import Foundation

class SimulatorProxy: MonoHandle, MonoClassInitializer {
    static var _class: OpaquePointer?
    static var _minionFactory: OpaquePointer!
    static var _getDuosStartingHealth: OpaquePointer!
    
    static var _members = [String: OpaquePointer]()
    
    static func initialize() {
        if SimulatorProxy._class == nil {
            SimulatorProxy._class = MonoHelper.loadClass(ns: "BobsBuddy.Simulation", name: "Simulator")
            SimulatorProxy._getDuosStartingHealth = MonoHelper.getMethod(SimulatorProxy._class, "GetDuosStartingHealth", 2)
            
            initializeFields(fields: [ "MinionFactory", "TrinketFactory", "AnomalyFactory", "ObjectiveFactory", "EnchantmentFactory" ])
        }
    }
    
    static func getDuosStartingHealth(_ health: Int32, _ teammateHealth: Int32?) -> Int32 {
        let params = UnsafeMutablePointer<UnsafeMutablePointer<Int32>?>.allocate(capacity: 2)
        let a = UnsafeMutablePointer<Int32>.allocate(capacity: 1)
        a.pointee = health
        params[0] = a.advanced(by: 0)
            
        let res = params.withMemoryRebound(to: UnsafeMutableRawPointer?.self, capacity: 2, {
            var val: Int32 = 0
            if let teammateHealth {
                val = teammateHealth
                $0[1] = UnsafeMutableRawPointer(mono_value_box(MonoHelper._monoInstance, mono_get_int32_class(), &val))
            } else {
                $0[1] = nil
            }

            let res = mono_runtime_invoke(SimulatorProxy._getDuosStartingHealth, nil, $0, nil)
            
            let r = mono_object_unbox(res)
            return r?.bindMemory(to: Int32.self, capacity: 1)[0] ?? 0
        })
        a.deallocate()
        params.deallocate()
        return res
    }
    
    override init() {
        super.init()
        
        let obj = MonoHelper.objectNew(clazz: SimulatorProxy._class!)
        set(obj: obj)
        
        let inst = self.get()
        
        mono_runtime_object_init(inst)
    }
    
    required init(obj: UnsafeMutablePointer<MonoObject>?) {
        fatalError("init(obj:) has not been implemented")
    }
    
    @MonoHandleField(field: "MinionFactory", owner: SimulatorProxy.self)
    var minionFactory: MinionFactoryProxy
    
    @MonoHandleField(field: "TrinketFactory", owner: SimulatorProxy.self)
    var trinketFactory: TrinketFactoryProxy
    
    @MonoHandleField(field: "AnomalyFactory", owner: SimulatorProxy.self)
    var anomalyFactory: AnomalyFactoryProxy
    
    @MonoHandleField(field: "ObjectiveFactory", owner: SimulatorProxy.self)
    var objectiveFactory: ObjectiveFactoryProxy
    
    @MonoHandleField(field: "EnchantmentFactory", owner: SimulatorProxy.self)
    var enchantmentFactory: EnchantmentFactoryProxy
}

