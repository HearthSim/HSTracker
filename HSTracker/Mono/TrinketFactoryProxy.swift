//
//  TrinketFactory.swift
//  HSTracker
//
//  Created by Francisco Moraes on 8/20/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class TrinketFactoryProxy: MonoHandle, MonoClassInitializer {

    internal static var _class: OpaquePointer?
    
    private static var _create: OpaquePointer!
    
    static var _members = [String: OpaquePointer]()
    
    static func initialize() {
        _class = MonoHelper.loadClass(ns: "BobsBuddy.Factory", name: "TrinketFactory")
        
        mono_class_init(_class)
        
        _create = MonoHelper.getMethod(TrinketFactoryProxy._class, "Create", 2)
    }
    
    required init(obj: UnsafeMutablePointer<MonoObject>?) {
        super.init(obj: obj)
    }
    
    func create(id: String, friendly: Bool) -> TrinketProxy {
        let params = UnsafeMutablePointer<OpaquePointer>.allocate(capacity: 2)

        id.withCString({
            params[0] = mono_string_new(MonoHelper._monoInstance, $0)
        })
        let ptrs = UnsafeMutablePointer<Int32>.allocate(capacity: 1)
        ptrs[0] = friendly ? 1 : 0

        params[1] = OpaquePointer(ptrs.advanced(by: 0))

        let res: TrinketProxy = params.withMemoryRebound(to: UnsafeMutableRawPointer?.self, capacity: 2, {
            let r = mono_runtime_invoke(TrinketFactoryProxy._create, self.get(), $0, nil)
            return TrinketProxy(obj: r)
        })
        params.deallocate()
        ptrs.deallocate()
        return res
    }
}
