//
//  CardEntity.swift
//  HSTracker
//
//  Created by Francisco Moraes on 5/10/23.
//  Copyright © 2023 Benjamin Michotte. All rights reserved.
//

import Foundation

class BloodGemProxy: MonoHandle, MonoClassInitializer {
    static var _class: OpaquePointer?
    
    static var _constructor: OpaquePointer!
    
    static var _members = [String: OpaquePointer]()

    static func initialize() {
        if BloodGemProxy._class == nil {
            BloodGemProxy._class = MonoHelper.loadClass(ns: "BobsBuddy", name: "BloodGem")
            
            BloodGemProxy._constructor = MonoHelper.getMethod(BloodGemProxy._class, ".ctor", 2)
        }
    }

    init(simulator: SimulatorProxy) {
        super.init()
        
        let obj = MonoHelper.objectNew(clazz: BloodGemProxy._class!)
        set(obj: obj)
        
        let inst = self.get()
        
        let params = UnsafeMutablePointer<UnsafeMutableRawPointer?>.allocate(capacity: 2)
        params[0] = nil
        params[1] = UnsafeMutableRawPointer(simulator.get())
        _ = mono_runtime_invoke(BloodGemProxy._constructor, inst, params, nil)
        
        params.deallocate()
    }
    
    required init(obj: UnsafeMutablePointer<MonoObject>?) {
        fatalError("init(obj:) has not been implemented")
    }
}
