//
//  CardEntity.swift
//  HSTracker
//
//  Created by Francisco Moraes on 5/10/23.
//  Copyright © 2023 Benjamin Michotte. All rights reserved.
//

import Foundation

class SpellCardEntityProxy: MonoHandle, MonoClassInitializer {
    static var _class: OpaquePointer?
    
    static var _constructor: OpaquePointer!
    
    static var _members = [String: OpaquePointer]()

    static func initialize() {
        if SpellCardEntityProxy._class == nil {
            SpellCardEntityProxy._class = MonoHelper.loadClass(ns: "BobsBuddy", name: "SpellCardEntity")
            
            SpellCardEntityProxy._constructor = MonoHelper.getMethod(SpellCardEntityProxy._class, ".ctor", 1)
        }
    }

    override init() {
        super.init()
        
        let obj = MonoHelper.objectNew(clazz: SpellCardEntityProxy._class!)
        set(obj: obj)
        
        let inst = self.get()
        
        let params = UnsafeMutablePointer<UnsafeMutableRawPointer?>.allocate(capacity: 1)
        params[0] = nil
        _ = mono_runtime_invoke(SpellCardEntityProxy._constructor, inst, params, nil)
        
        params.deallocate()
    }
    
    required init(obj: UnsafeMutablePointer<MonoObject>?) {
        fatalError("init(obj:) has not been implemented")
    }
}
