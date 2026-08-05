//
//  LockboxCardEntityProxy.swift
//  HSTracker
//
//  Created by Francisco Moraes on 8/4/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

class LockboxCardEntityProxy: MonoHandle, MonoClassInitializer {
    static var _class: OpaquePointer?
    
    static var _constructor: OpaquePointer!
    
    static var _members = [String: OpaquePointer]()

    static func initialize() {
        if LockboxCardEntityProxy._class == nil {
            LockboxCardEntityProxy._class = MonoHelper.loadClass(ns: "BobsBuddy", name: "LockboxCardEntity")
            
            LockboxCardEntityProxy._constructor = MonoHelper.getMethod(LockboxCardEntityProxy._class, ".ctor", 2)
        }
    }

    init(simulator: SimulatorProxy) {
        super.init()
        
        let obj = MonoHelper.objectNew(clazz: LockboxCardEntityProxy._class!)
        set(obj: obj)
        
        let inst = self.get()
        
        let params = UnsafeMutablePointer<UnsafeMutableRawPointer?>.allocate(capacity: 2)
        params[0] = nil
        params[1] = UnsafeMutableRawPointer(simulator.get())
        _ = mono_runtime_invoke(LockboxCardEntityProxy._constructor, inst, params, nil)
        
        params.deallocate()
    }
    
    required init(obj: UnsafeMutablePointer<MonoObject>?) {
        fatalError("init(obj:) has not been implemented")
    }
}
