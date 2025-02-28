//
//  EnchantmentProxy.swift
//  HSTracker
//
//  Created by Francisco Moraes on 2/25/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class EnchantmentProxy: MonoHandle, MonoClassInitializer {
    static var _class: OpaquePointer?
    
    static var _constructor: OpaquePointer!
    
    static var _members = [String: OpaquePointer]()
    
    static func initialize() {
        if EnchantmentProxy._class == nil {
            EnchantmentProxy._class = MonoHelper.loadClass(ns: "BobsBuddy.Enchantments", name: "Enchantment")
            
            EnchantmentProxy._constructor = MonoHelper.getMethod(EnchantmentProxy._class, ".ctor", 3)
            
            initializeProperties(properties: [ "ScriptDataNum1", "ScriptDataNum2" ])
        }
    }
    
    init(cardId: String, simulator: SimulatorProxy, controlledByPlayer: Bool) {
        super.init()
        
        let obj = MonoHelper.objectNew(clazz: EnchantmentProxy._class!)
        set(obj: obj)
        
        let inst = self.get()
        
        let ptrs = UnsafeMutablePointer<Int32>.allocate(capacity: 1)
        
        let params = UnsafeMutablePointer<UnsafeMutableRawPointer?>.allocate(capacity: 3)
        
        cardId.withCString {
            params[0] = UnsafeMutableRawPointer(mono_string_new(MonoHelper._monoInstance, $0))
            params[1] = UnsafeMutableRawPointer(simulator.get())
            params[2] = UnsafeMutableRawPointer(ptrs)
            
            _ = mono_runtime_invoke(EnchantmentProxy._constructor, inst, params, nil)
        }
        
        ptrs.deallocate()
        params.deallocate()
    }
    
    required init(obj: UnsafeMutablePointer<MonoObject>?) {
        super.init(obj: obj)
    }
    
    @MonoPrimitiveProperty(property: "ScriptDataNum1", owner: EnchantmentProxy.self)
    var scriptDataNum1: Int32
    
    @MonoPrimitiveProperty(property: "ScriptDataNum2", owner: EnchantmentProxy.self)
    var scriptDataNum2: Int32
}
