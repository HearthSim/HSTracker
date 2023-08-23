//
//  CardEntity.swift
//  HSTracker
//
//  Created by Francisco Moraes on 5/10/23.
//  Copyright © 2023 Benjamin Michotte. All rights reserved.
//

import Foundation

class MinionCardEntityProxy: MonoHandle, MonoClassInitializer {
    static var _class: OpaquePointer?
    
    static var _constructor: OpaquePointer!
    
    static var _members = [String: OpaquePointer]()

    static func initialize() {
        if MinionCardEntityProxy._class == nil {
            MinionCardEntityProxy._class = MonoHelper.loadClass(ns: "BobsBuddy", name: "MinionCardEntity")
            
            MinionCardEntityProxy._constructor = MonoHelper.getMethod(MinionCardEntityProxy._class, ".ctor", 3)
        }
    }

    init(minion: MinionProxy, simulator: SimulatorProxy) {
        super.init()
        
        let obj = MonoHelper.objectNew(clazz: MinionCardEntityProxy._class!)
        set(obj: obj)
        
        let inst = self.get()
        let minionInst = minion.get()
        let params = UnsafeMutablePointer<UnsafeMutableRawPointer?>.allocate(capacity: 3)
        params[0] = UnsafeMutableRawPointer(minionInst)
        params[1] = nil
        params[2] = UnsafeMutableRawPointer(simulator.get())
        _ = mono_runtime_invoke(MinionCardEntityProxy._constructor, inst, params, nil)
        
        params.deallocate()
    }
    
    required init(obj: UnsafeMutablePointer<MonoObject>?) {
        fatalError("init(obj:) has not been implemented")
    }
}
