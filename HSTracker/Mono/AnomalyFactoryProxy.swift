//
//  MinionFactoryProxy.swift
//  HSTracker
//
//  Created by Francisco Moraes on 8/12/20.
//  Copyright © 2020 Benjamin Michotte. All rights reserved.
//

import Foundation

class AnomalyFactoryProxy: MonoHandle, MonoClassInitializer {

    internal static var _class: OpaquePointer?
    
    private static var _create: OpaquePointer!
    
    static var _members = [String: OpaquePointer]()
    
    static func initialize() {
        _class = MonoHelper.loadClass(ns: "BobsBuddy.Factory", name: "AnomalyFactory")
        
        mono_class_init(_class)
        
        _create = MonoHelper.getMethod(AnomalyFactoryProxy._class, "Create", 1)
    }
    
    required init(obj: UnsafeMutablePointer<MonoObject>?) {
        super.init(obj: obj)
    }
    
    func create(id: String) -> AnomalyProxy {
        let params = UnsafeMutablePointer<OpaquePointer>.allocate(capacity: 1)

        id.withCString({
            params[0] = mono_string_new(MonoHelper._monoInstance, $0)
        })

        let res: AnomalyProxy = params.withMemoryRebound(to: UnsafeMutableRawPointer?.self, capacity: 1, {
            let r = mono_runtime_invoke(AnomalyFactoryProxy._create, self.get(), $0, nil)
            return AnomalyProxy(obj: r)
        })
        params.deallocate()
        return res
    }    
}
