//
//  TestInputProxy.swift
//  HSTracker
//
//  Created by Francisco Moraes on 8/11/20.
//  Copyright © 2020 Benjamin Michotte. All rights reserved.
//

import Foundation

class SimulationRunnerProxy: MonoHandle {
    static var _class: OpaquePointer?
    
    static var _simulateMultiThreaded: OpaquePointer!
    
    override init() {
        super.init()
        
        if SimulationRunnerProxy._class == nil {
            SimulationRunnerProxy._class = MonoHelper.loadClass(ns: "BobsBuddy.Simulation", name: "SimulationRunner")
            
            SimulationRunnerProxy._simulateMultiThreaded = mono_class_get_method_from_name(SimulationRunnerProxy._class, "SimulateMultiThreaded", 4 )
        }
                
        let obj = MonoHelper.objectNew(clazz: SimulationRunnerProxy._class!)
        set(obj: obj)
        
        let inst = self.get()
        
        mono_runtime_object_init(inst)
    }
    
    func simulateMultiThreaded(input: TestInputProxy, maxIterations: Int, threadCount: Int, maxDuration: Int = 1500) -> MonoHandle {
        let params = UnsafeMutablePointer<UnsafeMutableRawPointer?>.allocate(capacity: 4)
        let intPointers = UnsafeMutablePointer<Int>.allocate(capacity: 3)
        intPointers[0] = maxIterations
        intPointers[1] = threadCount
        intPointers[2] = maxDuration
        
        params[0] = UnsafeMutableRawPointer(input.get())
        params[1] = UnsafeMutableRawPointer(intPointers.advanced(by: 0))
        params[2] = UnsafeMutableRawPointer(intPointers.advanced(by: 1))
        params[3] = UnsafeMutableRawPointer(intPointers.advanced(by: 2))
        
        let res = mono_runtime_invoke(SimulationRunnerProxy._simulateMultiThreaded, self.get(), params, nil)
        intPointers.deallocate()
        params.deallocate()
        return MonoHandle(obj: res)
    }
}
