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
    
    static var _members = [String: OpaquePointer]()
    
    static func initialize() {
        if SimulatorProxy._class == nil {
            SimulatorProxy._class = MonoHelper.loadClass(ns: "BobsBuddy.Simulation", name: "Simulator")
            
            initializeFields(fields: [ "MinionFactory", "TrinketFactory", "AnomalyFactory", "ObjectiveFactory", "EnchantmentFactory" ])
        }
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
