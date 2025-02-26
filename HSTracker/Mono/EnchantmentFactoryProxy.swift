//
//  EnchantmentFactoryProxy.swift
//  HSTracker
//
//  Created by Francisco Moraes on 2/25/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class EnchantmentFactoryProxy: MonoHandle, MonoClassInitializer {
    
    internal static var _class: OpaquePointer?
    
    private static var _create: OpaquePointer!
    
    static var _members = [String: OpaquePointer]()
    
    static func initialize() {
        _class = MonoHelper.loadClass(ns: "BobsBuddy.Factory", name: "EnchantmentFactory")
        
        mono_class_init(_class)
        
        _create = MonoHelper.getMethod(EnchantmentFactoryProxy._class, "Create", 2)
    }
    
    required init(obj: UnsafeMutablePointer<MonoObject>?) {
        super.init(obj: obj)
    }
    
    func create(cardId: String, controlledByPlayer: Bool) -> EnchantmentProxy {
        let params = UnsafeMutablePointer<OpaquePointer>.allocate(capacity: 2)
        let ptrs = UnsafeMutablePointer<Int32>.allocate(capacity: 1)
        ptrs[0] = controlledByPlayer ? 1 : 0

        cardId.withCString({
            params[0] = mono_string_new(MonoHelper._monoInstance, $0)
            params[1] = OpaquePointer(ptrs.advanced(by: 0))
        })

        let res: EnchantmentProxy = params.withMemoryRebound(to: UnsafeMutableRawPointer?.self, capacity: 2, {
            let r = mono_runtime_invoke(EnchantmentFactoryProxy._create, self.get(), $0, nil)
            return EnchantmentProxy(obj: r)
        })
        ptrs.deallocate()
        params.deallocate()
        
        return res
    }
}
