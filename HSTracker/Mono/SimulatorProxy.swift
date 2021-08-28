//
//  TestInputProxy.swift
//  HSTracker
//
//  Created by Francisco Moraes on 8/11/20.
//  Copyright © 2020 Benjamin Michotte. All rights reserved.
//

import Foundation

class SimulatorProxy: MonoHandle {
    static var _class: OpaquePointer?
    
    override init() {
        super.init()
        
        if SimulatorProxy._class == nil {
            SimulatorProxy._class = MonoHelper.loadClass(ns: "BobsBuddy.Simulation", name: "Simulator")
        }
                
        let obj = MonoHelper.objectNew(clazz: SimulatorProxy._class!)
        set(obj: obj)
        
        let inst = self.get()
        
        mono_runtime_object_init(inst)
    }
}
