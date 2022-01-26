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
    
    static func initialize() {
        if SimulatorProxy._class == nil {
            SimulatorProxy._class = MonoHelper.loadClass(ns: "BobsBuddy.Simulation", name: "Simulator")
            SimulatorProxy._minionFactory = MonoHelper.getField(SimulatorProxy._class, "MinionFactory")
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
    
    func minionFactory() -> MinionFactoryProxy {
        let handle = MonoHelper.getField(obj: self, field: SimulatorProxy._minionFactory)
        return MinionFactoryProxy(obj: handle)
    }
}
