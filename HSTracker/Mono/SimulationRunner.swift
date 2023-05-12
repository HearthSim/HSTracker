//
//  TestInputProxy.swift
//  HSTracker
//
//  Created by Francisco Moraes on 8/11/20.
//  Copyright © 2020 Benjamin Michotte. All rights reserved.
//

import Foundation

struct UnsupportedInteraction: Error {
    
}

class SimulationRunnerProxy: MonoHandle, MonoClassInitializer {
    static var _class: OpaquePointer?
    
    static var _simulateMultiThreaded: OpaquePointer!
    
    static var _members = [String: OpaquePointer]()
    
    static func initialize() {
        if SimulationRunnerProxy._class == nil {
            SimulationRunnerProxy._class = MonoHelper.loadClass(ns: "BobsBuddy.Simulation", name: "SimulationRunner")
            
            SimulationRunnerProxy._simulateMultiThreaded = MonoHelper.getMethod(SimulationRunnerProxy._class, "SimulateMultiThreaded", 4 )
        }
    }
    
    override init() {
        super.init()
                
        let obj = MonoHelper.objectNew(clazz: SimulationRunnerProxy._class!)
        set(obj: obj)
        
        let inst = self.get()
        
        mono_runtime_object_init(inst)
    }
    
    required init(obj: UnsafeMutablePointer<MonoObject>?) {
        fatalError("init(obj:) has not been implemented")
    }
    
    func simulateMultiThreaded(input: InputProxy, maxIterations: Int, threadCount: Int, maxDuration: Int = 1500) -> MonoHandle {
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
