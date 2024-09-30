//
//  Scallywag.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/29/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class Scallywag: MonoClassInitializer {
    static var _class: OpaquePointer?
    static var _deathrattle: OpaquePointer!
    
    static var _members = [String: OpaquePointer]()
    
    static func initialize() {
        if Scallywag._class == nil {
            Scallywag._class = MonoHelper.loadClass(ns: "BobsBuddy.Minions.Pirate", name: "Scallywag")
            Scallywag._deathrattle = MonoHelper.getMethod(Scallywag._class, "Deathrattle", 1)
        }
    }
    
    static func deathrattle(golden: Bool) -> MonoHandle {
        let params = UnsafeMutablePointer<UnsafeMutablePointer<Int32>>.allocate(capacity: 1)
        let a = UnsafeMutablePointer<Int32>.allocate(capacity: 1)
        a.pointee = golden ? 1 : 0
        params[0] = a
        
        let result: UnsafeMutablePointer<MonoObject>? = params.withMemoryRebound(to: UnsafeMutableRawPointer?.self, capacity: 1, {
            return mono_runtime_invoke(Scallywag._deathrattle, nil, $0, nil)
        })
        a.deallocate()
        params.deallocate()
        return MonoHandle(obj: result)
    }
}
