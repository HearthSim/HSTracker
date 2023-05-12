//
//  CardEntity.swift
//  HSTracker
//
//  Created by Francisco Moraes on 5/10/23.
//  Copyright © 2023 Benjamin Michotte. All rights reserved.
//

import Foundation

class CardEntityProxy: MonoHandle, MonoClassInitializer {
    static var _class: OpaquePointer?
    
    static var _constructor: OpaquePointer!
    
    static var _members = [String: OpaquePointer]()

    static func initialize() {
        if CardEntityProxy._class == nil {
            CardEntityProxy._class = MonoHelper.loadClass(ns: "BobsBuddy", name: "CardEntity")
            
            CardEntityProxy._constructor = MonoHelper.getMethod(CardEntityProxy._class, ".ctor", 2)
        }
    }

    required init(id: String) {
        super.init()
        
        let obj = MonoHelper.objectNew(clazz: CardEntityProxy._class!)
        set(obj: obj)
        
        let inst = self.get()
        
        let params = UnsafeMutablePointer<OpaquePointer?>.allocate(capacity: 2)
        id.withCString({
            params[0] = mono_string_new(MonoHelper._monoInstance, $0)
            params[1] = nil
        })

        _ = params.withMemoryRebound(to: UnsafeMutableRawPointer?.self, capacity: 2, {
            mono_runtime_invoke(CardEntityProxy._constructor, inst, $0, nil)
        })
        
        params.deallocate()
    }
    
    required init(obj: UnsafeMutablePointer<MonoObject>?) {
        fatalError("init(obj:) has not been implemented")
    }
}
